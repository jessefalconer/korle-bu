# frozen_string_literal: true

class UnpackingEvent < ApplicationRecord
  belongs_to :packed_item, optional: false
  belongs_to :user, optional: false
  belongs_to :hospital, optional: false

  delegate :generated_name, :item, :category, to: :packed_item

  # Only checked for new events or a changed quantity: older records include
  # zero-quantity and over-unpacked events, and their timestamps stay editable.
  with_options if: :quantity_check_needed? do
    validates :quantity, numericality: { only_integer: true, greater_than: 0 }
    validate :quantity_within_remaining
  end

  paginates_per 25

  # A blank timestamp from a form means "now" (the column is NOT NULL).
  before_validation { self.timestamp ||= Time.current }

  after_commit do
    packed_item.save!
  end

  private

  def quantity_check_needed?
    new_record? || will_save_change_to_quantity? || will_save_change_to_packed_item_id?
  end

  # Locks the packed item's row for the rest of the save, so two unpacks
  # submitted at once (a double click, two tabs) can't both take the same stock.
  def quantity_within_remaining
    return if packed_item_id.nil? || quantity.to_i <= 0

    locked = PackedItem.lock.find_by(id: packed_item_id)
    return unless locked

    already = UnpackingEvent.where(packed_item_id: packed_item_id).where.not(id: id).sum(:quantity)
    available = [locked.quantity - already, 0].max
    errors.add(:quantity, "can't be more than the #{available} remaining") if quantity > available
  end
end
