# frozen_string_literal: true

class Hospital < ApplicationRecord
  STATUSES = %w[Active Deactivated].freeze

  belongs_to :user, optional: false
  belongs_to :warehouse, optional: false

  has_many :users, through: :warehouse, source: :users
  has_many :unpacking_events
  has_many :packed_items, through: :unpacking_events

  validates :status, inclusion: { in: STATUSES }

  paginates_per 25

  def active?
    status == "Active"
  end

  def full_address
    [street, postal_code, city, province, country].reject(&:blank?).join(", ")
  end

  def has_associations?
    reflections = Hospital.reflections.select do |_association_name, reflection|
      reflection.macro == :has_many
    end

    reflections.keys.map do |assoc|
      send(assoc).any?
    end.any?(true)
  end
end
