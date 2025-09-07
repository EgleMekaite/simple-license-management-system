# frozen_string_literal: true
class Subscription < ApplicationRecord
  belongs_to :account
  belongs_to :product

  validates :number_of_licenses, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :issued_at, presence: true
  validates :expires_at, presence: true
  validates :product_id, uniqueness: { scope: :account_id }

  validate :expires_after_issued

  before_destroy :ensure_no_license_assignments

  private

  def expires_after_issued
    return if issued_at.blank? || expires_at.blank?
    errors.add(:expires_at, "must be after issued_at") if expires_at <= issued_at
  end

  def ensure_no_license_assignments
    if LicenseAssignment.for_account(account_id).for_products(product_id).exists?
      errors.add(:base, "Cannot delete subscription while licenses are assigned")
      throw :abort
    end
  end
end
