# frozen_string_literal: true

class UnpackingEvent < ApplicationRecord
  belongs_to :packed_item
  belongs_to :user

  delegate :generated_name, to: :item

  after_commit do
    packed_item.recalculate_remaining_items
    packed_item.save!
  end
end