# frozen_string_literal: true

class Container < ApplicationRecord
  STATUSES = %w[Not\ Started Packing Completed].freeze

  belongs_to :user, optional: false
  belongs_to :shipment, optional: true

  has_many :pallets, dependent: :nullify
  has_many :container_items, class_name: "PackedItem", dependent: :destroy
  has_many :items, through: :container_items

  accepts_nested_attributes_for :container_items, allow_destroy: true, reject_if: ->(x) { x[:quantity].blank? }

  scope :unassigned, -> { where(shipment_id: nil) }
  scope :recent, -> { where("created_at > ?", 30.days.ago) }

  validates :name, :custom_uid, :user, presence: true
  validates :custom_uid, :name, uniqueness: true
  validates :status, inclusion: { in: STATUSES }

  paginates_per 10
end
