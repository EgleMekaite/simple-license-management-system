# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    association :account
    sequence(:name) { |n| "User #{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
  end
end


