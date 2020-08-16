# frozen_string_literal: true

class Box < ApplicationRecord
  belongs_to :user, optional: false
  # TODO: these optional trues are status=unassigned
  belongs_to :container, optional: true
  belongs_to :pallet, optional: true

  has_many :boxed_items
  has_many :items, through: :boxed_items

  accepts_nested_attributes_for :boxed_items, allow_destroy: true, reject_if: ->(x) { x[:quantity].blank? }

  scope :loose_box, -> { where(pallet_id: nil).where.not(container_id: nil) }
  scope :unassigned, -> { where(pallet_id: nil, container_id: nil) }

  paginates_per 10
end
