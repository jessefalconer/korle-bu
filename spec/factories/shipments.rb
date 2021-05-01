# frozen_string_literal: true

FactoryBot.define do
  factory :shipment do
    user
    receiving_warehouse { FactoryBot.create(:warehouse) }
    shipping_warehouse { FactoryBot.create(:warehouse) }
  end
end
