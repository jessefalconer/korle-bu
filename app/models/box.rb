# frozen_string_literal: true

class Box < ApplicationRecord
  STATUSES = %w[Not\ Started Packing Completed].freeze

  belongs_to :user, optional: false
  # TODO: these optional trues are status=unassigned
  belongs_to :container, optional: true
  belongs_to :pallet, optional: true

  has_many :box_items, class_name: "PackedItem", dependent: :destroy
  has_many :items, through: :box_items

  has_one :container, through: :pallet
  has_one :shipment, through: :container

  accepts_nested_attributes_for :box_items, allow_destroy: true, reject_if: ->(x) { x[:quantity].blank? }

  scope :loose_box, -> { where(pallet_id: nil).where.not(container_id: nil) }
  scope :unassigned, -> { where(pallet_id: nil, container_id: nil) }
  scope :recent, -> { where("created_at > ?", 30.days.ago) }

  delegate :container, to: :pallet, allow_nil: true
  delegate :shipment, to: :pallet, allow_nil: true

  validates :name, :custom_uid, :user, presence: true
  validates :custom_uid, :name, uniqueness: true
  validates :status, inclusion: { in: STATUSES }

  paginates_per 10
end
