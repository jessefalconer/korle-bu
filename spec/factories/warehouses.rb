# frozen_string_literal: true

FactoryBot.define do
  factory :warehouse do
    user

    sequence(:name) { |n| "Warehouse #{n}" }
  end
end
