# frozen_string_literal: true

require 'set'

class LicenseAssigner
  # @param account_id [UUID]
  # @param product_ids [Array<UUID>]
  # @param user_ids [Array<UUID>]
  def initialize(account_id, product_ids, user_ids)
    @account_id = account_id.to_s
    @product_ids = Array(product_ids).map(&:to_s)
    @user_ids = Array(user_ids).map(&:to_s)
    @messages = []
  end

  # @return [Array(Integer, Array<String>)] total_assigned, messages
  def call
    return [0, ["No products selected."]] if product_ids.empty?
    return [0, ["No users selected."]] if user_ids.empty?

    assign_licenses
  end

  private

  attr_reader :account_id, :product_ids, :user_ids, :messages

  def assign_licenses
    assignment_rows = product_ids.flat_map do |product_id|
      rows, info_message = build_rows_and_message(product_id)
      messages << info_message if info_message
      rows
    end

    return [0, messages] if assignment_rows.empty?

    total_assigned = create_license_assignments(assignment_rows)

    [total_assigned, messages]
  end

  def create_license_assignments(rows)
    total_assigned = 0
    LicenseAssignment.transaction do
      # Also consider using `upsert_all` or managing rows in batches
      rows.each do |attributes|
        begin
          LicenseAssignment.create!(attributes)
          total_assigned += 1
        rescue ActiveRecord::RecordInvalid => e
          messages << e.record.errors.full_messages.join(', ')
        rescue ActiveRecord::RecordNotUnique
        end
      end
    end
    total_assigned
  end

  def build_rows_and_message(product_id)
    subscription = subscriptions_by_product[product_id]
    unless subscription
      messages << "No subscription for product #{product_label(product_id)}."
      return [[], nil]
    end

    available_licenses_count = remaining_license_count(product_id, subscription)
    eligible_user_ids_for_product = eligible_user_ids(product_id)
    duplicates_count = duplicates_count_for(eligible_user_ids_for_product.size)

    if eligible_user_ids_for_product.size > available_licenses_count
      exhausted_capacity_result(product_id, available_licenses_count, duplicates_count)
    else
      successful_assignment_result(product_id, eligible_user_ids_for_product, duplicates_count)
    end
  end

  def remaining_license_count(product_id, subscription)
    total_licenses = subscription.number_of_licenses
    current_licenses = assigned_licenses_per_product[product_id].to_i
    [total_licenses - current_licenses, 0].max
  end

  def eligible_user_ids(product_id)
    already_assigned_for_product = licensed_user_ids_by_product[product_id] || Set.new
    user_ids.reject { |user_id| already_assigned_for_product.include?(user_id) }
  end

  def build_assignment_rows(product_id, user_ids_to_assign)
    user_ids_to_assign.map do |user_id|
      { account_id: account_id, product_id: product_id, user_id: user_id }
    end
  end

  def capacity_warning_message(product_id, remaining_license_count)
    "Cannot assign to all selected users: #{product_label(product_id)} has #{remaining_license_count} license(s) remaining."
  end

  def exhausted_capacity_result(product_id, remaining_licenses_count, duplicates_count)
    capacity_message = capacity_warning_message(product_id, remaining_licenses_count)
    add_duplicates_message(product_id, duplicates_count)
    [[], capacity_message]
  end

  def successful_assignment_result(product_id, eligible_ids, duplicates_count)
    assignment_rows = build_assignment_rows(product_id, eligible_ids)
    add_duplicates_message(product_id, duplicates_count)
    [assignment_rows, nil]
  end

  def add_duplicates_message(product_id, duplicates_count)
    return if duplicates_count.to_i <= 0
    messages << duplicates_warning_message(product_id, duplicates_count)
  end

  def duplicates_warning_message(product_id, duplicates_count)
    "[#{product_label(product_id)}] #{duplicates_count} user(s) already licensed."
  end

  def duplicates_count_for(eligible_count)
    [user_ids.size - eligible_count, 0].max
  end

  def product_label(product_id)
    product_names[product_id] || product_id
  end

  def product_names
    @product_names ||= Product.where(id: product_ids).pluck(:id, :name).to_h
  end

  def subscriptions_by_product
    @subscriptions_by_product ||= Subscription.where(account_id: account_id, product_id: product_ids)
                                              .index_by { |s| s.product_id }
  end

  def assigned_licenses_per_product
    @assigned_licenses_per_product ||= begin
      pairs = assignment_pairs_for_products
      pairs.group_by { |product_id, _| product_id }
           .transform_values(&:size)
    end
  end

  def assignment_pairs_for_products
    @assignment_pairs_for_products ||= LicenseAssignment
      .for_account(account_id)
      .for_products(product_ids)
      .pluck(:product_id, :user_id)
  end

  def licensed_user_ids_by_product
    @licensed_user_ids_by_product ||= group_pairs_by_product(assignment_pairs_for_products)
  end

  def group_pairs_by_product(pairs)
    pairs.group_by { |product_id, _| product_id }
         .transform_values { |rows| rows.map { |_, user_id| user_id }.to_set }
  end
end
