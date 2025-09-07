# frozen_string_literal: true
class Product < ApplicationRecord
  has_many :subscriptions, dependent: :destroy
  has_many :license_assignments, dependent: :restrict_with_error

  scope :ordered_by_name, -> { order(:name) }

  validates :name, presence: true
end
