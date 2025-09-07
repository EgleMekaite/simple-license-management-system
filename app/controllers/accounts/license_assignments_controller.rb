# frozen_string_literal: true

module Accounts
  class LicenseAssignmentsController < ApplicationController
    before_action :set_account

    def index
      @assignments = LicenseAssignment
        .where(account: @account)
        .joins(:product, :user)
        .preload(:product, :user)
        .order('users.name ASC, products.name ASC')
        .group_by { |assignment| assignment.user.name }
    end

    def create
      product_ids = Array(params[:product_ids]).compact_blank.uniq
      user_ids = Array(params[:user_ids]).compact_blank.uniq

      total_assigned, messages = ::LicenseAssigner.new(@account.id, product_ids, user_ids).call

      set_flash_for_assignment(total_assigned, messages)
      redirect_to account_path(@account)
    end

    def unassign
      product_ids = Array(params[:product_ids]).compact_blank.uniq
      user_ids = Array(params[:user_ids]).compact_blank.uniq

      removed = LicenseAssignment.where(account: @account, product_id: product_ids, user_id: user_ids).delete_all
      redirect_to account_path(@account), notice: "Unassigned #{removed} license(s)."
    end

    private

    def set_account
      @account = Account.find(params[:account_id])
    end

    def set_flash_for_assignment(total_assigned, messages)
      message_parts = []
      message_parts << (total_assigned > 0 ? "Assigned #{total_assigned} license(s)." : "No licenses assigned.")
      message_parts.concat(Array(messages))
      flash_key = total_assigned > 0 && Array(messages).blank? ? :notice : :alert
      flash[flash_key] = message_parts.join(' ')
    end
  end
end


