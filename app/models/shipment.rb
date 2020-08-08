# frozen_string_literal: true

class Shipment < ApplicationRecord
  STATUSES = ["Not Started", "In Progress", "Ready to Ship", "In Transit", "Received"].freeze

  belongs_to :user, optional: false

  belongs_to :receiving_warehouse, class_name: "Warehouse", optional: false
  belongs_to :shipping_warehouse, class_name: "Warehouse", optional: false

  has_many :containers
end
