# frozen_string_literal: true
class Account < ApplicationRecord
  has_many :users
  has_many :subscriptions
  has_many :license_assignments

  validates :name, presence: true
end
