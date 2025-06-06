# frozen_string_literal: true

class Pallet < ApplicationRecord
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
  scope :reassignable, -> { where(status: [WAREHOUSED, STAGED, IN_PROGRESS]) }

  delegate :shipment, to: :container, allow_nil: true

  validates :name, :custom_uid, :user, presence: true
  validates :custom_uid, :name, uniqueness: true # rubocop:disable Rails/UniqueValidationWithoutIndex
  validates :status, inclusion: { in: STATUSES }

  paginates_per 35

  after_initialize :set_defaults, if: :new_record?

  before_save do
    orphan_pallet if status_will_change_to_warehoused_or_staged?
    adopt_status if adopting_by_parent?
  end

  after_save do
    cascade_statuses if !status_changed_to_warehoused_or_staged?
    cascade_packed_items_location if saved_change_to_container_id
  end

  STATUSES.each do |stat|
    define_method("#{stat.parameterize(separator: "_")}?") do
      status == stat
    end
  end

  def adopting_by_parent?
    container_id_change_to_be_saved&.first.nil? && (staged? || warehoused?) && !will_save_change_to_status?
  end

  private

  def status_will_change_to_warehoused_or_staged?
    status_change_to_be_saved&.last.in?([WAREHOUSED, STAGED])
  end

  def status_changed_to_warehoused_or_staged?
    return false unless saved_change_to_status?

    from, to = saved_change_to_status
    [WAREHOUSED, STAGED].include?(to) && ![WAREHOUSED, STAGED].include?(from)
  end

  def adopt_status
    return unless container

    self.status = container.status
  end

  def orphan_pallet
    self.container_id = nil
  end

  # TODO: Move these to a service
  def cascade_statuses
    boxes.where.not(status: status).find_each { |box| box.update(status: status) }
    pallet_items.where.not(status: status).find_each { |pi| pi.update(status: status) }
  end

  def cascade_packed_items_location
    pallet_items.each(&:save!)
    box_items.each(&:save!)
  end

  def set_defaults
    cid = Pallet.maximum(:custom_uid).to_i + 1
    name = "PALLET-#{cid}"
    self.name = name
    self.custom_uid = cid
  end
end
