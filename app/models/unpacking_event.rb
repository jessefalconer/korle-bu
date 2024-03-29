# frozen_string_literal: true

class UnpackingEvent < ApplicationRecord
  belongs_to :packed_item, optional: false
  belongs_to :user, optional: false
  belongs_to :hospital, optional: false

  delegate :generated_name, :item, :category, to: :packed_item

  paginates_per 25

  after_commit do
    packed_item.save!
  end
end
