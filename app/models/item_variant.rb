# frozen_string_literal: true

class ItemVariant < ApplicationRecord
  belongs_to :item, optional: false
  belongs_to :user, optional: false

  STANDARD_SIZES = %w[Assorted\ Sizes XXXS XXS XS Small Medium Large XL XXL XXXL].freeze
  INFANT_SIZES = %w[Infant Newborn Preemie Infant\ Size\ 1 Infant\ Size\ 2 Infant\ Size\ 2.5
                    Infant\ Size\ 3 Infant\ Size\ 3.5 Infant\ Size\ 4 Infant\ Size\ 4.5 Infant\ Size\ 5 Infant\ Size\ 6 Infant\ Size\ 7] +
                 STANDARD_SIZES.map { |s| "Infant #{s}" }.freeze
  CHILD_SIZES = %w[Child] + STANDARD_SIZES.map { |s| "Child #{s}" }.freeze
  ADULT_SIZES = %w[Adult] + STANDARD_SIZES.map { |s| "Adult #{s}" }.freeze

  GROUPED_SIZES = [
    ["Standard", STANDARD_SIZES],
    ["Infant", INFANT_SIZES],
    ["Child", CHILD_SIZES],
    ["Adult", ADULT_SIZES]
  ].freeze
end
