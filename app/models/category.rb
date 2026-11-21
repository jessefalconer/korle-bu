# frozen_string_literal: true

class Category < ApplicationRecord
  belongs_to :user, optional: false

  has_many :items
  has_many :pallets

  paginates_per 25

  # Items and pallets point at their category, so it stays while any do.
  def deletion_blockers
    [(count_of(items.count, "item") if items.exists?),
     (count_of(pallets.count, "pallet") if pallets.exists?)].compact.map { |used| "#{used} use it" }
  end
end
