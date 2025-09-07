# frozen_string_literal: true

module Accounts
  class UsersController < ApplicationController
    before_action :set_account

    def index
      @users = @account.users.ordered_by_name
    end

    def new
      @user = @account.users.new
    end

    def create
      @user = @account.users.create!(user_params)
      redirect_to account_users_path(@account), notice: "User was successfully created."
    end

    private

    def set_account
      @account = Account.find(params[:account_id])
    end

    def user_params
      params.require(:user).require(:name)
      params.require(:user).require(:email)
      params.require(:user).permit(:name, :email)
    end
  end
end


