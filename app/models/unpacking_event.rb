# frozen_string_literal: true

class UnpackingEvent < ApplicationRecord
  belongs_to :packed_item, optional: false
  belongs_to :user, optional: false
  belongs_to :hospital, optional: false

  delegate :generated_name, :item, to: :packed_item

  after_commit do
    packed_item.save!
  end
end
