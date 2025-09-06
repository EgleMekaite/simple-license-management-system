# frozen_string_literal: true

module Accounts
  class LicenseAssignmentsController < ApplicationController
    before_action :set_account

    def index
      @assignments = LicenseAssignment.where(account: @account).includes(:product, :user).order('products.name, users.name')
    end

    def create
      product_ids = params.require(:product_ids).compact_blank.uniq
      user_ids = params.require(:user_ids).compact_blank.uniq

      total_assigned, messages = LicenseAssigner.new(@account.id, product_ids, user_ids).call

      base = total_assigned > 0 ? "Assigned #{total_assigned} license(s)." : "No licenses assigned."
      full_message = ([base] + Array(messages)).join(' ')
      flash[Array(messages).any? ? :alert : :notice] = full_message
      redirect_to account_path(@account)
    end

    def unassign
      product_ids = params.require(:product_ids)
      user_ids = params.require(:user_ids)

      removed = LicenseAssignment.where(account: @account, product_id: product_ids, user_id: user_ids).delete_all
      redirect_to account_path(@account), notice: "Unassigned #{removed} license(s)."
    end

    private

    def set_account
      @account = Account.find(params[:account_id])
    end
  end
end


