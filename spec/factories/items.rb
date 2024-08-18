# frozen_string_literal: true

FactoryBot.define do
  factory :item do
    user

    sequence(:object) { |n| "Item #{n}" }
  end
end
