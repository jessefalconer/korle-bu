# frozen_string_literal: true

class Container < ApplicationRecord
  belongs_to :user, optional: false
  belongs_to :shipment, optional: false

  has_many :pallets
  has_many :containerized_items
end
