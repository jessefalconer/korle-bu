# frozen_string_literal: true

class PackedItem < ApplicationRecord
  belongs_to :box, optional: true
  belongs_to :container, optional: true
  belongs_to :item, optional: false
  belongs_to :pallet, optional: true
  belongs_to :shipment, optional: true
  belongs_to :user, optional: false

  has_one :category, through: :item

  has_many :unpacking_events, dependent: :destroy

  scope :with_inventory, -> { left_joins(:unpacking_events).where("remaining_quantity > ?", 0) }
  scope :with_events, -> { joins(:unpacking_events).uniq }

  accepts_nested_attributes_for :unpacking_events, allow_destroy: true, reject_if: ->(x) { x[:quantity].blank? }

  with_options presence: true do
    validates :box, if: ->(packed_item) { packed_item.container.blank? && packed_item.pallet.blank? }
    validates :container, if: ->(packed_item) { packed_item.box.blank? && packed_item.pallet.blank? }
    validates :pallet, if: ->(packed_item) { packed_item.box.blank? && packed_item.container.blank? }
  end

  before_save do
    recalculate_remaining_items
    self.shipment = box&.shipment || pallet&.shipment || container&.shipment
  end

  delegate :generated_name, to: :item

  def self.by_item
    all.group_by(&:item).each_with_object({}) do |(item, packed_items), hash|
      hash[packed_items.first.generated_name] = { category: (item&.category&.name || "N/A"), quantity: packed_items.sum(&:quantity) }
    end
  end

  def self.by_category
    all.group_by(&:category).each_with_object({}) do |(_item, packed_items), hash|
      hash[packed_items.first&.category&.name || "N/A"] =
        packed_items.group_by(&:item).each_with_object({}) { |(b, i), h| h[b.generated_name] = i.sum(&:quantity) }
    end
  end

  def recalculate_remaining_items
    self.remaining_quantity = quantity.to_i - unpacking_events.sum(:quantity)
    self.remaining_weight = weight.to_i - unpacking_events.sum(:weight)
  end
end
