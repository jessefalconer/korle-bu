# frozen_string_literal: true

class PackedItem < ApplicationRecord
  belongs_to :box, optional: true
  belongs_to :container, optional: true
  belongs_to :item, optional: false
  belongs_to :pallet, optional: true
  belongs_to :shipment, optional: true
  belongs_to :user, optional: false

  with_options presence: true do
    validates :box, if: ->(packed_item) { packed_item.container.blank? && packed_item.pallet.blank? }
    validates :container, if: ->(packed_item) { packed_item.box.blank? && packed_item.pallet.blank? }
    validates :pallet, if: ->(packed_item) { packed_item.box.blank? && packed_item.container.blank? }
  end

  after_save do
    self.shipment = box&.shipment || pallet&.shipment || container&.shipment
  end

  delegate :generated_name, to: :item
end
