# frozen_string_literal: true

class Box < ApplicationRecord
  STATUSES = [
    IN_PROGRESS = "In Progress",
    COMPLETE = "Complete",
    RECEIVED = "Received"
  ].freeze

  belongs_to :user, optional: false
  belongs_to :container, optional: true
  belongs_to :pallet, optional: true

  has_many :box_items, class_name: "PackedItem", dependent: :destroy
  has_many :items, through: :box_items

  accepts_nested_attributes_for :box_items, allow_destroy: true, reject_if: ->(x) { x[:quantity].blank? }

  scope :loose_boxes, -> { where(pallet_id: nil).where.not(container_id: nil) }
  scope :unassigned, -> { where(pallet_id: nil, container_id: nil) }

  validates :name, :custom_uid, :user, presence: true
  validates :custom_uid, :name, uniqueness: true
  validates :status, inclusion: { in: STATUSES }

  paginates_per 25

  after_initialize :set_defaults, if: :new_record?

  before_validation do
    if will_save_change_to_pallet_id? && pallet
      self.container = nil
    end
    if will_save_change_to_container_id? && container
      self.pallet = nil
    end
  end

  after_save do
    cascade_packed_items_location if saved_change_to_container_id || saved_change_to_pallet_id
  end

  def shipment
    container&.shipment || pallet&.container&.shipment
  end

  private

  def cascade_packed_items_location
    box_items.where.not(shipment_id: shipment&.id).find_each { |bi| bi.update(shipment_id: shipment&.id) }
  end

  def set_defaults
    cid = Box.maximum(:custom_uid).to_i + 1
    name = "BOX-#{cid}"
    self.name = name
    self.custom_uid = cid
    self.status = IN_PROGRESS
  end
end
