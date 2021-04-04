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
  has_many :complete_shipments, -> { where(status: Shipment::COMPLETE) },
           class_name: "Shipment", foreign_key: "shipping_warehouse_id", inverse_of: :shipping_warehouse
  has_many :complete_packed_items, through: :complete_shipments, source: :packed_items

  validates :status, inclusion: { in: STATUSES }

  paginates_per 25

  def active?
    status == "Active"
  end

  def full_address
    [street, postal_code, city, province, country].reject(&:blank?).join(", ")
  end

  def associations?
    reflections = Warehouse.reflections.select do |_association_name, reflection|
      reflection.macro == :has_many
    end

    reflections.keys.map do |assoc|
      send(assoc).any?
    end.any?(true)
  end
end
