# frozen_string_literal: true

class Box < ApplicationRecord
  STATUSES = ["In Progress", "Complete", "Received"].freeze

  belongs_to :user, optional: false
  belongs_to :container, optional: true
  belongs_to :pallet, optional: true

  has_many :box_items, class_name: "PackedItem", dependent: :destroy
  has_many :items, through: :box_items

  # has_one :shipment, polymorphic: true

  accepts_nested_attributes_for :box_items, allow_destroy: true, reject_if: ->(x) { x[:quantity].blank? }

  scope :loose_boxes, -> { where(pallet_id: nil).where.not(container_id: nil) }
  scope :unassigned, -> { where(pallet_id: nil, container_id: nil) }
  scope :recent, -> { where("created_at > ?", 30.days.ago) }

  validates :name, :custom_uid, :user, presence: true
  validates :custom_uid, :name, uniqueness: true
  validates :status, inclusion: { in: STATUSES }

  paginates_per 25

  before_validation do
    if will_save_change_to_pallet_id? && pallet
      self.container = nil
    end
    if will_save_change_to_container_id? && container
      self.pallet = nil
    end
  end

  def shipment
    container&.shipment || pallet&.container&.shipment
  end
end
