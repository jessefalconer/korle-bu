# frozen_string_literal: true

class Warehouse < ApplicationRecord
  STATUSES = %w[Active Deactivated].freeze

  belongs_to :user, optional: false

  has_many :users
  has_many :received_shipments, -> { where(status: Shipment::RECEIVED) },
           class_name: "Shipment", foreign_key: "receiving_warehouse_id", inverse_of: :receiving_warehouse
  has_many :received_packed_items, through: :received_shipments, source: :packed_items
  has_many :in_progress_shipments, -> { where(status: Shipment::IN_PROGRESS) },
           class_name: "Shipment", foreign_key: "shipping_warehouse_id", inverse_of: :shipping_warehouse
  has_many :in_progress_packed_items, through: :in_progress_shipments, source: :packed_items

  validates :status, inclusion: { in: STATUSES }

  paginates_per 25

  def active?
    status == "Active"
  end
end
