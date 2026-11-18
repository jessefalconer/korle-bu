# frozen_string_literal: true

FactoryBot.define do
  factory :category do
    user

    sequence(:name) { |n| "Category #{n}" }
  end
end
