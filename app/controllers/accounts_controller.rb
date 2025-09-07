# frozen_string_literal: true

class AccountsController < ApplicationController
  def index
    @accounts = Account.order(:name)
  end

  def show
    @account = Account.find(params[:id])
    @suppress_layout_flash = true
    @users = @account.users.ordered_by_name
    @subscription_rows = subscription_rows_for(@account)
  end

  def new
    @account = Account.new
  end

  def create
    @account = Account.create!(account_params)
    redirect_to @account, notice: "Account was successfully created."
  end

  private

  def account_params
    params.require(:account).require(:name)
    params.require(:account).permit(:name)
  end

  def subscription_rows_for(account)
    subscriptions = subscriptions_with_products_for(account)
    return [] if subscriptions.empty?

    used_counts = used_counts_by_product_for(account.id, subscriptions.map(&:product_id))
    subscriptions.map { |subscription| build_subscription_row(subscription, used_counts) }
  end

  def subscriptions_with_products_for(account)
    account.subscriptions
           .joins(:product)
           .preload(:product)
           .order('products.name ASC')
  end

  def used_counts_by_product_for(account_id, product_ids)
    LicenseAssignment
      .where(account_id: account_id, product_id: product_ids)
      .group(:product_id)
      .count
  end

  def build_subscription_row(subscription, used_counts)
    used_licenses = used_counts[subscription.product_id].to_i
    remaining = [subscription.number_of_licenses - used_licenses, 0].max
    {
      product_id: subscription.product_id,
      product_name: subscription.product.name,
      number_of_licenses: subscription.number_of_licenses,
      remaining: remaining
    }
  end
end


