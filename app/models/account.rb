# frozen_string_literal: true
class Account < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :subscriptions, dependent: :destroy
  has_many :license_assignments, dependent: :destroy

  validates :name, presence: true
end
