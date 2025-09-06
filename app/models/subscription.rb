# frozen_string_literal: true
class Subscription < ApplicationRecord
  belongs_to :account
  belongs_to :product

  validates :number_of_licenses, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :issued_at, presence: true
  validates :expires_at, presence: true

  validate :expires_after_issued

  private

  def expires_after_issued
    return if issued_at.blank? || expires_at.blank?
    errors.add(:expires_at, "must be after issued_at") if expires_at <= issued_at
  end
end
