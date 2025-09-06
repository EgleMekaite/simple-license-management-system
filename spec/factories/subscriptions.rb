# frozen_string_literal: true

FactoryBot.define do
  factory :subscription do
    association :account
    association :product
    number_of_licenses { 1 }
    issued_at { Time.current }
    expires_at { 1.day.from_now }
  end
end


