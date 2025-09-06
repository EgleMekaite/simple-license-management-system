# frozen_string_literal: true

FactoryBot.define do
  factory :license_assignment do
    association :account
    association :user
    association :product
  end
end


