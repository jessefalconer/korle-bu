# frozen_string_literal: true

class Pallet < ApplicationRecord
  belongs_to :user, optional: false
  # TODO: this optional true is status=unassigned
  belongs_to :container, optional: true
  has_many :boxes
  has_many :palletized_items

  accepts_nested_attributes_for :palletized_items, allow_destroy: true, reject_if: ->(x) { x[:quantity].blank? }

  scope :unnassigned, -> { where(container_id: nil) }

  paginates_per 10
end
