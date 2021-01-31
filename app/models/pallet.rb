# frozen_string_literal: true

class Pallet < ApplicationRecord
  STATUSES = ["In Progress", "Complete", "Received"].freeze

  belongs_to :user, optional: false
  belongs_to :container, optional: true

  has_many :boxes, dependent: :nullify
  has_many :pallet_items, class_name: "PackedItem", dependent: :destroy
  has_many :items, through: :pallet_items

  has_one :shipment, through: :container

  accepts_nested_attributes_for :pallet_items, allow_destroy: true, reject_if: ->(x) { x[:quantity].blank? }

  scope :unassigned, -> { where(container_id: nil) }
  scope :recent, -> { where("created_at > ?", 30.days.ago) }

  delegate :shipment, to: :container, allow_nil: true

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
    boxes.where.not(status: status).find_each { |p| p.update(status: status) }
  end
end
