# frozen_string_literal: true

class PackedItem < ApplicationRecord
  STATUSES = [
    WAREHOUSED = "Warehoused",
    STAGED = "Staged",
    IN_PROGRESS = "In Progress",
    COMPLETE = "Complete",
    RECEIVED = "Received",
    ARCHIVED = "Archived"
  ].freeze

  belongs_to :box, optional: true, inverse_of: :box_items
  belongs_to :container, optional: true, inverse_of: :container_items
  belongs_to :item, optional: false
  belongs_to :pallet, optional: true, inverse_of: :pallet_items
  belongs_to :shipment, optional: true, inverse_of: :packed_items
  belongs_to :user, optional: false

  has_one :category, through: :item

  has_many :unpacking_events, dependent: :delete_all

  scope :with_inventory, -> { left_joins(:unpacking_events).where("remaining_quantity > ?", 0).uniq }
  scope :with_events, -> { joins(:unpacking_events).uniq }
  scope :staged, -> { where(box_id: nil, pallet_id: nil, container_id: nil, status: STAGED) }
  scope :warehoused, -> { where(box_id: nil, pallet_id: nil, container_id: nil, status: WAREHOUSED) }
  # Unarchived items with stock left, in received shipments bound for the warehouse.
  # Joins items, so callers can filter or order on items columns.
  scope :received_in, lambda { |warehouse_id|
    left_joins(:item, :shipment).where(
      "packed_items.remaining_quantity > 0 AND
      packed_items.status <> ? AND
      shipments.receiving_warehouse_id = ? AND
      shipments.status = ?",
      ARCHIVED, warehouse_id, Shipment::RECEIVED
    )
  }
  # Preloads the parent chain the unpack forms read for location names and breadcrumbs.
  scope :with_parents, lambda {
    preload(
      box: [{ container: :shipment }, { pallet: { container: :shipment } }],
      pallet: { container: :shipment },
      container: :shipment
    )
  }

  accepts_nested_attributes_for :unpacking_events, allow_destroy: true, reject_if: ->(x) { x[:quantity].blank? }

  validates :status, inclusion: { in: STATUSES }, if: ->(packed_item) { packed_item.will_not_assign? }
  with_options presence: true do
    validates :box, if: ->(packed_item) { packed_item.box.present? && packed_item.status.blank? }
    validates :container, if: ->(packed_item) { packed_item.container.present? && packed_item.status.blank? }
    validates :pallet, if: ->(packed_item) { packed_item.pallet.present? && packed_item.status.blank? }
  end

  paginates_per 35

  delegate :generated_name, :category, to: :item

  before_save do
    set_with_parent_status
    set_shipment
    recalculate_remaining_quantity
  end

  # Bulk equivalent of the status and shipment parts of the before_save callback, for
  # every packed item in the current scope, in one UPDATE. An item takes the status of
  # its first parent (box, then pallet, then container) and the shipment of that
  # parent chain. Only rows that actually change are written and get a new updated_at.
  # Remaining quantity isn't touched, because moving or re-statusing a parent doesn't change it.
  def self.sync_with_parents!
    computed = unscoped
      .from("packed_items pi")
      .joins(<<~SQL.squish)
        LEFT JOIN boxes b ON b.id = pi.box_id
        LEFT JOIN containers bc ON bc.id = b.container_id
        LEFT JOIN pallets bp ON bp.id = b.pallet_id
        LEFT JOIN containers bpc ON bpc.id = bp.container_id
        LEFT JOIN pallets p ON p.id = pi.pallet_id
        LEFT JOIN containers pc ON pc.id = p.container_id
        LEFT JOIN containers c ON c.id = pi.container_id
      SQL
      .where("pi.id IN (#{select(:id).to_sql})")
      .select(<<~SQL.squish)
        pi.id,
        CASE
          WHEN pi.box_id IS NULL AND pi.pallet_id IS NULL AND pi.container_id IS NULL THEN pi.status
          ELSE COALESCE(b.status, p.status, c.status)
        END AS new_status,
        COALESCE(
          CASE WHEN b.container_id IS NOT NULL THEN bc.shipment_id ELSE bpc.shipment_id END,
          pc.shipment_id,
          c.shipment_id
        ) AS new_shipment_id
      SQL

    connection.exec_update(<<~SQL.squish, "PackedItem Sync With Parents", [])
      UPDATE packed_items
      SET status = computed.new_status,
          shipment_id = computed.new_shipment_id,
          updated_at = #{connection.quote(Time.current)}
      FROM (#{computed.to_sql}) computed
      WHERE packed_items.id = computed.id
        AND (packed_items.status IS DISTINCT FROM computed.new_status
             OR packed_items.shipment_id IS DISTINCT FROM computed.new_shipment_id)
    SQL
  end

  def self.by_item
    all.group_by(&:item).each_with_object({}) do |(item, packed_items), hash|
      hash[item.generated_name] = {
        category: (item.category&.name || "N/A"),
        quantity: packed_items.sum(&:quantity),
        weight: packed_items.pluck(:weight).compact.sum,
        location: packed_items.map(&:location_name).uniq.join(", ")
      }
    end
  end

  def self.by_category
    all.group_by(&:category).each_with_object({}) do |(category, packed_items), hash|
      hash[category&.name || "N/A"] =
        packed_items.group_by(&:item).each_with_object({}) do |(item, pi), h|
          h[item.generated_name] = {
            quantity: pi.sum(&:quantity),
            weight: pi.pluck(:weight).compact.sum,
            location: pi.map(&:location_name).uniq.join(", ")
          }
        end
    end
  end

  def will_not_assign?
    box.blank? && pallet.blank? && container.blank?
  end

  def location_name
    return parent.name if parent

    status
  end

  def parent
    box || pallet || container
  end

  private

  def set_shipment
    self.shipment = box&.shipment || pallet&.shipment || container&.shipment
  end

  def set_with_parent_status
    self.status = parent&.status unless will_not_assign?
  end

  def recalculate_remaining_quantity
    self.remaining_quantity = quantity.to_i - unpacking_events.sum(:quantity)
  end
end
