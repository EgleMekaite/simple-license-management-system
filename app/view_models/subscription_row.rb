# frozen_string_literal: true

# Lightweight immutable view model for rendering subscription rows on the
# account show page.
class SubscriptionRow
  attr_reader :product_id, :product_name, :number_of_licenses, :remaining

  def initialize(product_id:, product_name:, number_of_licenses:, remaining:)
    @product_id = product_id
    @product_name = product_name
    @number_of_licenses = number_of_licenses
    @remaining = remaining
    freeze
  end
end


