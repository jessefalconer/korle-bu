# frozen_string_literal: true

class Pallet < ApplicationRecord
  STATUSES = %w[Not\ Started Packing Completed].freeze

  belongs_to :user, optional: false
  # TODO: this optional true is status=unassigned
  belongs_to :container, optional: true

  has_many :boxes
  has_many :palletized_items
  has_many :items, through: :palletized_items

  accepts_nested_attributes_for :palletized_items, allow_destroy: true, reject_if: ->(x) { x[:quantity].blank? }

  scope :unassigned, -> { where(container_id: nil) }

  delegate :shipment, to: :container, allow_nil: true

  validates :name, :custom_uid, :user, presence: true
  validates :custom_uid, :name, uniqueness: true
  validates :status, inclusion: { in: STATUSES }

  paginates_per 10
end
