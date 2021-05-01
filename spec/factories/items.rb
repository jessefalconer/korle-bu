# frozen_string_literal: true

FactoryBot.define do
  factory :item do
    user

    sequence(:object) { Faker::Appliance.equipment }
  end
end
