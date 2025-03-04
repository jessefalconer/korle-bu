# frozen_string_literal: true

class Box < ApplicationRecord
  STATUSES = [
    WAREHOUSED = "Warehoused",
    STAGED = "Staged",
    IN_PROGRESS = "In Progress",
    COMPLETE = "Complete",
    RECEIVED = "Received",
    ARCHIVED = "Archived"
  ].freeze

  belongs_to :user, optional: false
  belongs_to :container, optional: true
  belongs_to :pallet, optional: true

  has_many :box_items, class_name: "PackedItem", dependent: :destroy
  has_many :items, through: :box_items

  accepts_nested_attributes_for :box_items, allow_destroy: true, reject_if: ->(x) { x[:quantity].blank? }

  scope :assigned, -> { where("pallet_id IS NOT NULL OR container_id IS NOT NULL") }
  scope :staged, -> { left_outer_joins(:pallet).where("boxes.status = ? OR pallets.status = ?", STAGED, STAGED) }
  scope :in_progress, -> { where(status: IN_PROGRESS) }
  scope :warehoused, -> { left_outer_joins(:pallet).where("boxes.status = ? OR pallets.status = ?", WAREHOUSED, WAREHOUSED) }
  scope :reassignable, -> { where(status: [WAREHOUSED, STAGED, IN_PROGRESS]) }

  validates :name, :custom_uid, :user, presence: true
  validates :custom_uid, :name, uniqueness: true # rubocop:disable Rails/UniqueValidationWithoutIndex
  validates :status, inclusion: { in: STATUSES }

  paginates_per 35

  after_initialize :set_defaults, if: :new_record?

  before_validation do
    if will_save_change_to_pallet_id? && pallet
      self.container = nil
    end
    if will_save_change_to_container_id? && container
      self.pallet = nil
    end
  end

  before_save do
    orphan_box if orphanable_status?
    adopt_status if adopting_by_parent?
  end

  after_save do
    cascade_packed_items_location if saved_change_to_container_id || saved_change_to_pallet_id
    cascade_statuses if saved_change_to_status && cascadable?
  end

  STATUSES.each do |stat|
    define_method("#{stat.parameterize(separator: "_")}?") do
      status == stat
    end
  end

  def cascadable?
    complete? || received? || archived? || saved_change_to_status?(from: [WAREHOUSED, STAGED])
  end

  def shipment
    container&.shipment || pallet&.container&.shipment
  end

  def orphanable_status?
    will_save_change_to_status?(to: [WAREHOUSED, STAGED])
  end

  def adopting_by_parent?
    (will_save_change_to_container_id?(from: nil) || will_save_change_to_pallet_id?(from: nil)) && (staged? || warehoused?) && !will_save_change_to_status?
  end

  private

  def adopt_status
    self.status = pallet&.status || container&.status
  end

  def orphan_box
    self.container_id = nil
    self.pallet_id = nil
  end

  # TODO: Move these to a service
  def cascade_packed_items_location
    box_items.each(&:save!)
  end

  def cascade_statuses
    box_items.where.not(status: status).find_each { |bi| bi.update(status: status) }
  end

  def set_defaults
    cid = Box.maximum(:custom_uid).to_i + 1
    name = "BOX-#{cid}"
    self.name = name
    self.custom_uid = cid
  end
end
