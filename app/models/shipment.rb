# frozen_string_literal: true

class Shipment < ApplicationRecord
  STATUSES = ["Not Started", "In Progress", "Ready to Ship", "In Transit", "Received"].freeze

  belongs_to :user, optional: false
  belongs_to :receiving_warehouse, class_name: "Warehouse", optional: false
  belongs_to :shipping_warehouse, class_name: "Warehouse", optional: false

  has_many :containers, dependent: :nullify
  has_many :container_items, through: :containers
  has_many :pallets, through: :containers
  has_many :pallet_items, through: :pallets
  has_many :boxes, through: :pallets
  has_many :box_items, through: :boxes
  has_many :packed_items

  validates :name, :custom_uid, :user, presence: true
  validates :custom_uid, :name, uniqueness: true
  validates :status, inclusion: { in: STATUSES }

  paginates_per 25
end
