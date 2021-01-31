# frozen_string_literal: true

class Container < ApplicationRecord
  STATUSES = ["In Progress", "Complete", "Received"].freeze

  belongs_to :user, optional: false
  belongs_to :shipment, optional: true

  has_many :boxes, dependent: :nullify
  has_many :pallets, dependent: :nullify
  has_many :pallet_boxes, through: :pallets, source: :boxes
  has_many :container_items, class_name: "PackedItem", dependent: :destroy
  has_many :items, through: :container_items

  accepts_nested_attributes_for :container_items, allow_destroy: true, reject_if: ->(x) { x[:quantity].blank? }

  scope :unassigned, -> { where(shipment_id: nil) }
  scope :recent, -> { where("created_at > ?", 30.days.ago) }

  validates :name, :custom_uid, :user, presence: true
  validates :custom_uid, :name, uniqueness: true
  validates :status, inclusion: { in: STATUSES }

  paginates_per 25

  after_save do
    cascade_statuses if saved_change_to_status && cascadable?
  end

  def cascadable?
    status == "Complete" || status == "Received"
  end

  private

  # TODO: Move this to a service
  def cascade_statuses
    boxes.where.not(status: status).find_each { |b| b.update(status: status) }
    pallets.where.not(status: status).find_each { |p| p.update(status: status) }
  end
end
