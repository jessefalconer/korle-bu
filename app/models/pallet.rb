# frozen_string_literal: true

class Pallet < ApplicationRecord
  STATUSES = [
    WAREHOUSED = "Warehoused",
    STAGED = "Staged",
    IN_PROGRESS = "In Progress",
    COMPLETE = "Complete",
    RECEIVED = "Received"
  ].freeze

  belongs_to :user, optional: false
  belongs_to :container, optional: true
  belongs_to :category, optional: true

  has_many :boxes, dependent: :nullify
  has_many :box_items, through: :boxes
  has_many :pallet_items, class_name: "PackedItem", dependent: :destroy
  has_many :items, through: :pallet_items

  has_one :shipment, through: :container

  accepts_nested_attributes_for :pallet_items, allow_destroy: true, reject_if: ->(x) { x[:quantity].blank? }

  scope :assigned, -> { where.not(container_id: nil) }
  scope :staged, -> { where(container_id: nil, status: STAGED) }
  scope :in_progress, -> { where(status: IN_PROGRESS) }
  scope :warehoused, -> { where(container_id: nil, status: WAREHOUSED) }

  delegate :shipment, to: :container, allow_nil: true

  validates :name, :custom_uid, :user, presence: true
  validates :custom_uid, :name, uniqueness: true
  validates :status, inclusion: { in: STATUSES }

  paginates_per 25

  after_save do
    cascade_statuses if saved_change_to_status && cascadable?
    cascade_packed_items_location if saved_change_to_container_id && container&.shipment
  end

  after_initialize :set_defaults, if: :new_record?

  def cascadable?
    status == "Complete" || status == "Received"
  end

  private

  # TODO: Move these to a service
  def cascade_statuses
    boxes.where.not(status: status).find_each { |p| p.update(status: status) }
  end

  def cascade_packed_items_location
    pallet_items.where.not(shipment_id: container.shipment_id).find_each { |pi| pi.update(shipment_id: container.shipment_id) }
    box_items.where.not(shipment_id: container.shipment_id).find_each { |bi| bi.update(shipment_id: container.shipment_id) }
  end

  def set_defaults
    cid = Pallet.maximum(:custom_uid).to_i + 1
    name = "PALLET-#{cid}"
    self.name = name
    self.custom_uid = cid
    self.status = IN_PROGRESS
  end
end
