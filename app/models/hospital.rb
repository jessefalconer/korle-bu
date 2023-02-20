# frozen_string_literal: true

class Hospital < ApplicationRecord
  STATUSES = [
    ACTIVE = "Active",
    DEACTIVATED = "Deactivated"
  ].freeze

  belongs_to :user, optional: false
  belongs_to :warehouse, optional: false

  has_many :users, through: :warehouse, source: :users
  has_many :unpacking_events
  has_many :packed_items, through: :unpacking_events

  validates :status, inclusion: { in: STATUSES }
  validates :name, uniqueness: true, presence: true  # rubocop:disable Rails/UniqueValidationWithoutIndex

  paginates_per 25

  def active?
    status == "Active"
  end

  def full_address
    [street, postal_code, city, province, country].reject(&:blank?).join(", ")
  end
end
