# frozen_string_literal: true
class LicenseAssignment < ApplicationRecord
  belongs_to :account
  belongs_to :user
  belongs_to :product

  validates :account, presence: true
  validates :user, presence: true
  validates :product, presence: true
  validates :product_id, uniqueness: { scope: [:account_id, :user_id] }

  scope :for_account, ->(account_id) { where(account_id: account_id) }
  scope :for_products, ->(product_ids) { where(product_id: product_ids) }
end
