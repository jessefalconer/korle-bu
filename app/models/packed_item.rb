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
