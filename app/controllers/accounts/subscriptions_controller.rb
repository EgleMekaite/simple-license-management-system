# frozen_string_literal: true

module Accounts
  class SubscriptionsController < ApplicationController
    before_action :set_account
    before_action :load_products, only: [:new, :create]

    def index
      @subscriptions = @account.subscriptions.includes(:product).order(:created_at)
    end

    def new
      @subscription = @account.subscriptions.new
    end

    def create
      @subscription = @account.subscriptions.create!(create_subscription_params)
      redirect_to account_subscriptions_path(@account), notice: "Subscription was successfully created."
    end

    private

    def set_account
      @account = Account.find(params[:account_id])
    end

    def subscription_params
      params.require(:subscription).require(:product_id)
      params.require(:subscription).require(:number_of_licenses)
      params.require(:subscription).require(:expires_at)
      params.require(:subscription).permit(:product_id, :number_of_licenses, :expires_at)
    end

    def create_subscription_params
      subscription_params.merge(issued_at: Time.current)
    end

    def load_products
      @products = Product.order(:name)
    end
  end
end


