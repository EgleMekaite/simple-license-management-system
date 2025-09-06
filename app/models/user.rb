# frozen_string_literal: true
class User < ApplicationRecord
  belongs_to :account

  has_many :license_assignments

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }
end
