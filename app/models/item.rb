# frozen_string_literal: true

class Item < ApplicationRecord
  include PgSearch::Model

  paginates_per 25

  pg_search_scope :search_by_generated_name,
                  against: :generated_name,
                  using: {
                    tsearch: {
                      prefix: true,
                      any_word: true
                    }
                  },
                  ranked_by: ":trigram"

  belongs_to :user, optional: false
  belongs_to :category, optional: true

  has_many :packed_items, dependent: :destroy
  has_many :item_boxes, dependent: :destroy # Remove this after legacy data

  has_one_attached :photo

  scope :unverified, -> { where(verified: false) }
  scope :uncategorized, -> { where(category: nil) }
  scope :flagged, -> { where(flagged: true) }

  validates :generated_name, uniqueness: true

  STANDARD_SIZES = %w[XXXS XXS XS Small Medium Large XL XXL XXXL].freeze
  INFANT_SIZES = %w[Infant] + STANDARD_SIZES.map { |s| "Infant #{s}" }.freeze
  CHILD_SIZES = %w[Child] + STANDARD_SIZES.map { |s| "Child #{s}" }.freeze
  ADULT_SIZES = %w[Adult] + STANDARD_SIZES.map { |s| "Adult #{s}" }.freeze
  VOLUMES = %w[mL dL L floz cc qt pt gal].freeze
  LENGTHS = %w[nm μm mm cm m km ga in ft].freeze
  MASSES = %w[ng μg mg g kg lb oz mmol mol].freeze
  UNITS = VOLUMES + LENGTHS + MASSES
  RATIOS = %w[%] + MASSES.map { |m| VOLUMES.map { |v| "#{m}/#{v}" } }.flatten.freeze

  GROUPED_MEASUREMENTS = [
    ["Length", LENGTHS],
    ["Volume", VOLUMES],
    ["Mass", MASSES],
    ["Concentration", RATIOS]
  ].freeze

  GROUPED_SIZES = [
    ["Standard", STANDARD_SIZES],
    ["Infant", INFANT_SIZES],
    ["Child", CHILD_SIZES],
    ["Adult", ADULT_SIZES]
  ]

  before_validation do
    sanitize_whitespace
    self.generated_name = process_name.presence || "Unnamed Item"
  end

  def self.item_instances(item)
    PackedItem.where(item_id: item.id).count
  end

  def process_name
    [brand.to_s.titleize, object, standardized_size.to_s,
     package.to_s, numerical_1_phrase.to_s, numerical_2_phrase.to_s,
     area_phrase.to_s, range_phrase.to_s].reject(&:empty?).join(" ").squish
  end

  # TODO: Lots of repetition here, can be refactored
  def numerical_1_phrase
    return if numerical_size_1.blank?

    "#{strip_trailing_zero(numerical_size_1)}#{numerical_units_1} #{numerical_description_1.to_s.titleize}"
  end

  def numerical_2_phrase
    return if numerical_size_2.blank?

    "#{strip_trailing_zero(numerical_size_2)}#{numerical_units_2} #{numerical_description_2.to_s.titleize}"
  end

  def area_phrase
    return if area_1.blank? || area_2.blank?

    "#{strip_trailing_zero(area_1)}x#{strip_trailing_zero(area_2)}#{area_units} #{area_description.to_s.titleize}"
  end

  def range_phrase
    return if range_1.blank? || range_2.blank?

    "#{strip_trailing_zero(range_1)}-#{strip_trailing_zero(range_2)}#{range_units} #{range_description.to_s.titleize}"
  end

  def package
    return if packaged_quantity.blank?

    "#{packaged_quantity}-Pack"
  end

  def strip_trailing_zero(num)
    num.to_s.sub(/\.?0+$/, "")
  end

  def trigram(word)
    return [] if word.strip == ""

    parts = []
    padded = "  #{word} ".downcase
    padded.chars.each_cons(3) { |w| parts << w.join }
    parts
  end

  def name_similarity(comparison_item)
    tri_1 = trigram(generated_name)
    tri_2 = trigram(comparison_item.generated_name)

    return 0.0 if [tri_1, tri_2].any? { |arr| arr.size.zero? }

    # Find number of trigrams shared between them
    same_size = (tri_1 & tri_2).size
    # Find unique total trigrams in both arrays
    all_size = (tri_1 | tri_2).size

    (same_size.to_f / all_size * 100).round(2)
  end

  private

  def sanitize_whitespace
    attribute_names.each do |name|
      if send(name).respond_to?(:squish)
        send("#{name}=", send(name).squish)
      end
    end
  end
end
