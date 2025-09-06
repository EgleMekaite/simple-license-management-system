# frozen_string_literal: true

class ProductsController < ApplicationController
  def index
    @products = Product.order(:name)
  end

  def show
    @product = Product.find(params[:id])
  end

  def new
    @product = Product.new
  end

  def create
    @product = Product.create!(product_params)
    redirect_to @product, notice: "Product was successfully created."
  end

  private

  def product_params
    params.require(:product).require(:name)
    params.require(:product).permit(:name, :description)
  end
end


