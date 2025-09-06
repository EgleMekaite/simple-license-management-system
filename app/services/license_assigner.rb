# frozen_string_literal: true
require 'set'

class LicenseAssigner
  # @param account_id [UUID]
  # @param product_ids [Array<UUID>]
  # @param user_ids [Array<UUID>]
  def initialize(account_id, product_ids, user_ids)
    @account_id = account_id
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
    total_assigned = 0
    rows_to_insert = []

    product_ids.each do |product_id|
      rows_for_product, info_message = build_rows_and_message(product_id)
      rows_to_insert.concat(rows_for_product)
      messages << info_message if info_message
    end

    if rows_to_insert.any?
      result = LicenseAssignment.insert_all(
        rows_to_insert,
        unique_by: :index_license_assignments_on_account_user_product,
        record_timestamps: true
      )
      total_assigned = result.count
    end

    [total_assigned, messages]
  end

  def build_rows_and_message(product_id)
    subscription = subscriptions_by_product[product_id]
    unless subscription
      messages << "No subscription for product #{product_names[product_id]}."
      return [[], nil]
    end

    remaining_licenses = remaining_capacity(product_id, subscription)
    candidates = candidate_user_ids(product_id)
    to_assign = candidates.first(remaining_licenses)

    rows = build_assignment_rows(product_id, to_assign)
    info_message = capacity_message(product_id, candidates, to_assign, remaining_licenses)

    [rows, info_message]
  end

  def remaining_capacity(product_id, subscription)
    total_licenses = subscription.number_of_licenses
    current_licenses = assigned_licenses_per_product[product_id].to_i
    [total_licenses - current_licenses, 0].max
  end

  def candidate_user_ids(product_id)
    already_assigned_for_product = assigned_product_licenses[product_id] || Set.new
    user_ids.reject { |user_id| already_assigned_for_product.include?(user_id) }
  end

  def build_assignment_rows(product_id, user_ids_to_assign)
    user_ids_to_assign.map do |user_id|
      { account_id: account_id, product_id: product_id, user_id: user_id }
    end
  end

  def capacity_message(product_id, candidates, to_assign, remaining_licenses)
    skipped_capacity = candidates.size - to_assign.size
    return nil unless skipped_capacity > 0

    "[#{product_label(product_id)}] insufficient capacity (#{remaining_licenses} remaining)."
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
    @assigned_licenses_per_product ||= LicenseAssignment
      .for_account(account_id)
      .for_products(product_ids)
      .group(:product_id)
      .count
  end

  def existing_assignment_pairs
    @existing_assignment_pairs ||= LicenseAssignment
      .for_account(account_id)
      .for_products(product_ids)
      .for_users(user_ids)
      .pluck(:product_id, :user_id)
  end

  def assigned_product_licenses
    @assigned_product_licenses ||= group_pairs_by_product(existing_assignment_pairs)
  end

  def group_pairs_by_product(pairs)
    pairs.group_by { |product_id, _| product_id.to_s }
         .transform_values { |rows| rows.map { |_, user_id| user_id.to_s }.to_set }
  end
end
