# frozen_string_literal: true

class AccountsController < ApplicationController
  def index
    @accounts = Account.order(:name)
  end

  def show
    @account = Account.find(params[:id])
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
end


