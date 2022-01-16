# frozen_string_literal: true

FactoryBot.define do
  factory :item do
    user

    sequence(:generated_name) { Faker::Appliance.equipment }
  end
end
