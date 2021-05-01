# frozen_string_literal: true

FactoryBot.define do
  factory :unpacking_event do
    user
    packed_item
  end
end
