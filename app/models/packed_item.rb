# frozen_string_literal: true

class PackedItem < ApplicationRecord
  belongs_to :box, optional: true
  belongs_to :container, optional: true
  belongs_to :item, optional: false
  belongs_to :pallet, optional: true
  belongs_to :shipment, optional: true
  belongs_to :user, optional: false

  has_one :category, through: :item

  with_options presence: true do
    validates :box, if: ->(packed_item) { packed_item.container.blank? && packed_item.pallet.blank? }
    validates :container, if: ->(packed_item) { packed_item.box.blank? && packed_item.pallet.blank? }
    validates :pallet, if: ->(packed_item) { packed_item.box.blank? && packed_item.container.blank? }
  end

  after_save do
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
end
