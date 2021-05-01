# frozen_string_literal: true

FactoryBot.define do
  factory :packed_item do
    user
    item
    box
    pallet
    container
    shipment
  end
end
