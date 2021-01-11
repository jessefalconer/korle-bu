# frozen_string_literal: true

class Shipment < ApplicationRecord
  STATUSES = ["In Progress", "Complete", "Received"].freeze

  belongs_to :user, optional: false
  belongs_to :receiving_warehouse, class_name: "Warehouse", optional: false
  belongs_to :shipping_warehouse, class_name: "Warehouse", optional: false

  has_many :containers, dependent: :nullify
  has_many :container_items, through: :containers
  has_many :container_boxes, through: :containers, source: :boxes
  has_many :pallets, through: :containers
  has_many :pallet_items, through: :pallets
  has_many :pallet_boxes, through: :pallets, source: :boxes
  has_many :pallet_box_items, through: :pallet_boxes, source: :box_items
  has_many :container_box_items, through: :container_boxes, source: :box_items
  has_many :packed_items

  validates :name, :custom_uid, :user, presence: true
  validates :custom_uid, :name, uniqueness: true
  validates :status, inclusion: { in: STATUSES }

  paginates_per 25

  def current_location
    case status
    when "In Progress"
      shipping_warehouse.name
    when "Complete"
     "In Transit to #{receiving_warehouse.name}"
    when "Received"
      receiving_warehouse.name
    else
      "No Warehouses Assigned"
    end
  end
end
