# frozen_string_literal: true

class Container < ApplicationRecord
  STATUSES = [
    IN_PROGRESS = "In Progress",
    COMPLETE = "Complete",
    RECEIVED = "Received"
  ].freeze

  belongs_to :user, optional: false
  belongs_to :shipment, optional: true

  has_many :boxes, dependent: :nullify
  has_many :box_items, through: :boxes
  has_many :pallets, dependent: :nullify
  has_many :pallet_items, through: :pallets
  has_many :pallet_boxes, through: :pallets, source: :boxes
  has_many :pallet_box_items, through: :pallet_boxes, source: :box_items
  has_many :container_items, class_name: "PackedItem", dependent: :destroy
  has_many :items, through: :container_items

  accepts_nested_attributes_for :container_items, allow_destroy: true, reject_if: ->(x) { x[:quantity].blank? }

  scope :staged, -> { where(shipment_id: nil) }
  scope :in_progress, -> { where(status: IN_PROGRESS) }

  validates :name, :custom_uid, :user, presence: true
  validates :custom_uid, :name, uniqueness: true
  validates :status, inclusion: { in: STATUSES }

  paginates_per 25

  after_save do
    cascade_statuses if saved_change_to_status && cascadable?
    cascade_packed_items_location if saved_change_to_shipment_id
  end

  after_initialize :set_defaults, if: :new_record?

  def cascadable?
    status == "Complete" || status == "Received"
  end

  private

  # TODO: Move these to a service
  def cascade_statuses
    boxes.where.not(status: status).find_each { |b| b.update(status: status) }
    pallets.where.not(status: status).find_each { |p| p.update(status: status) }
  end

  def cascade_packed_items_location
    container_items.where.not(shipment_id: shipment_id).find_each { |ci| ci.update(shipment_id: shipment_id) }
    pallet_items.where.not(shipment_id: shipment_id).find_each { |pi| pi.update(shipment_id: shipment_id) }
    pallet_box_items.where.not(shipment_id: shipment_id).find_each { |pbi| pbi.update(shipment_id: shipment_id) }
    box_items.where.not(shipment_id: shipment_id).find_each { |bi| bi.update(shipment_id: shipment_id) }
  end

  def set_defaults
    cid = Container.maximum(:custom_uid).to_i + 1
    name = "CONTAINER-#{cid}"
    self.name = name
    self.custom_uid = cid
    self.status = IN_PROGRESS
  end
end
