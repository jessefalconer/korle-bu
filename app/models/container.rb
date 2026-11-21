# frozen_string_literal: true

class Container < ApplicationRecord
  STATUSES = [
    IN_PROGRESS = "In Progress",
    COMPLETE = "Complete",
    RECEIVED = "Received",
    ARCHIVED = "Archived"
  ].freeze

  belongs_to :user, optional: false
  belongs_to :shipment, optional: true

  after_initialize :set_defaults, if: :new_record?
  # Before :nullify unassigns them (prepend), so we still know what was inside
  before_destroy :note_contents, prepend: true
  after_destroy :resync_former_contents

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
  # Receiver filter (ListFilter): through the shipment; nil means any warehouse.
  scope :received_by, ->(warehouse_id = nil) { where(shipment_id: Shipment.received_by(warehouse_id).select(:id)) }
  scope :in_progress, -> { where(status: IN_PROGRESS) }

  validates :name, :custom_uid, presence: true
  validates :custom_uid, :name, uniqueness: true # rubocop:disable Rails/UniqueValidationWithoutIndex
  validates :status, inclusion: { in: STATUSES }

  paginates_per 35

  after_save do
    cascade_statuses if saved_change_to_status && cascadable?
    cascade_packed_items_location if saved_change_to_shipment_id
  end

  STATUSES.each do |stat|
    define_method("#{stat.parameterize(separator: "_")}?") do
      status == stat
    end
  end

  def cascadable?
    complete? || received? || archived?
  end

  # ------------------------------------------------------------ Deleting
  def requires_typed_delete?
    true
  end

  def deletion_impact
    impact = packed_lines_deleted(container_items, "packed directly in it")
    pallet_count = pallets.count
    box_count = boxes.count
    if (pallet_count + box_count).positive?
      held = [(count_of(pallet_count, "pallet") if pallet_count.positive?),
              (count_of(box_count, "box") if box_count.positive?)].compact
      impact << "Its #{held.to_sentence} will be unassigned from it, not deleted."
    end
    impact
  end

  private

  # Boxes and pallets still update one by one, because they have their own callbacks.
  # Packed items are synced in bulk.
  def cascade_statuses
    boxes.where.not(status: status).find_each { |b| b.update(status: status) }
    pallets.where.not(status: status).find_each { |p| p.update(status: status) }
    PackedItem.where(container_id: id).sync_with_parents!
    container_items.reset
  end

  def cascade_packed_items_location
    pallet_ids = Pallet.where(container_id: id).select(:id)
    box_ids = Box.where(container_id: id).or(Box.where(pallet_id: pallet_ids)).select(:id)

    PackedItem.where(container_id: id)
      .or(PackedItem.where(pallet_id: pallet_ids))
      .or(PackedItem.where(box_id: box_ids))
      .sync_with_parents!
    [container_items, pallet_items, pallet_box_items, box_items].each(&:reset)
  end

  def set_defaults
    cid = Container.maximum(:custom_uid).to_i + 1
    name = "CONTAINER-#{cid}"
    self.name = name
    self.custom_uid = cid
    self.status = IN_PROGRESS
  end

  # Unassigning skips the boxes' and pallets' own callbacks, so the packed items
  # inside would keep this container's shipment (and show up as received stock
  # with nowhere to be). Re-derive their shipment and status from what's left.
  def note_contents
    @former_pallet_ids = pallets.ids
    @former_box_ids = Box.where(container_id: id).or(Box.where(pallet_id: @former_pallet_ids)).ids
  end

  def resync_former_contents
    PackedItem.where(pallet_id: @former_pallet_ids).or(PackedItem.where(box_id: @former_box_ids)).sync_with_parents!
  end
end
