# frozen_string_literal: true

class Shipment < ApplicationRecord
  STATUSES = [
    IN_PROGRESS = "In Progress",
    COMPLETE = "Complete",
    RECEIVED = "Received",
    ARCHIVED = "Archived"
  ].freeze

  belongs_to :user, optional: false
  belongs_to :receiving_warehouse, class_name: "Warehouse", optional: false
  belongs_to :shipping_warehouse, class_name: "Warehouse", optional: false

  after_initialize :set_defaults, if: :new_record?
  after_destroy :resync_former_contents

  has_many :containers, dependent: :nullify
  has_many :container_items, through: :containers
  has_many :container_boxes, through: :containers, source: :boxes
  has_many :pallets, through: :containers
  has_many :pallet_items, through: :pallets
  has_many :pallet_boxes, through: :pallets, source: :boxes
  has_many :pallet_box_items, through: :pallet_boxes, source: :box_items
  has_many :container_box_items, through: :container_boxes, source: :box_items
  has_many :packed_items
  has_many :box_items, -> { where(container_id: nil) }, class_name: "PackedItem", inverse_of: :shipment

  validates :name, :custom_uid, presence: true
  validates :custom_uid, :name, uniqueness: true # rubocop:disable Rails/UniqueValidationWithoutIndex
  validates :status, inclusion: { in: STATUSES }

  paginates_per 25

  after_save do
    cascade_statuses if saved_change_to_status && cascadable?
  end

  STATUSES.each do |stat|
    define_method("#{stat.parameterize(separator: "_")}?") do
      status == stat
    end
  end

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

  def cascadable?
    complete? || received? || archived?
  end

  # Summary numbers for the show page, computed in a single query.
  def packed_item_stats
    unique, instances, quantity, weight, earliest, latest = packed_items.pick(Arel.sql(<<~SQL.squish))
      COUNT(DISTINCT item_id), COUNT(*), SUM(quantity), SUM(weight), MIN(expiry_date), MAX(expiry_date)
    SQL

    {
      unique_items: unique.to_i,
      instances: instances.to_i,
      quantity: quantity.to_i,
      weight: weight.to_f.round(4),
      earliest_expiry: earliest,
      latest_expiry: latest
    }
  end

  # ------------------------------------------------------------ Deleting
  def requires_typed_delete?
    true
  end

  def deletion_impact
    count = containers.count
    return [] if count.zero?

    ["Its #{count_of(count, "container")} will be unassigned from it, not deleted."]
  end

  private

  # TODO: Move this to a service
  def cascade_statuses
    containers.where.not(status: status).find_each { |c| c.update(status: status) }
  end

  def set_defaults
    cid = Shipment.maximum(:custom_uid).to_i + 1
    name = "SHIPMENT-#{cid}"
    self.name = name
    self.custom_uid = cid
    self.status = IN_PROGRESS
  end

  # Unassigning the containers skips their callbacks, so everything packed in them
  # would keep pointing at this (now deleted) shipment.
  def resync_former_contents
    PackedItem.where(shipment_id: id).sync_with_parents!
  end
end
