# frozen_string_literal: true

class Container < ApplicationRecord
  belongs_to :user, optional: false
  belongs_to :shipment, optional: false

  has_many :pallets
  has_many :containerized_items

  accepts_nested_attributes_for :containerized_items, allow_destroy: true, reject_if: ->(x) { x[:quantity].blank? }

  scope :unnassigned, -> { where(shipment_id: nil) }
end
