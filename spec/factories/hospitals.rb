# frozen_string_literal: true

FactoryBot.define do
  factory :hospital do
    warehouse
    user

    sequence(:name) { |n| "Hospital #{n}" }
  end
end
