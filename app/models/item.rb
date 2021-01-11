# frozen_string_literal: true

class Item < ApplicationRecord
  include PgSearch::Model

  paginates_per 25

  pg_search_scope :search_by_generated_name, against: [:generated_name],
    using: {
      tsearch: { prefix: true }
    }

  belongs_to :user, optional: false
  belongs_to :category, optional: true

  has_many :packed_items, dependent: :destroy
  has_many :item_boxes, dependent: :destroy # Remove this after legacy data

  has_one_attached :photo

  validates :generated_name, uniqueness: true

  STANDARD_SIZES = %w[XXXS XXS XS Small Medium Large XL XXL XXXL Infant Child Assorted Adult].freeze
  VOLUMES = %w[mL dL L floz cc qt pt gal].freeze
  LENGTHS = %w[nm μm mm cm m km ga in ft].freeze
  MASSES = %w[ng μg mg g kg lb oz mmol mol].freeze

  UNITS = VOLUMES + LENGTHS + MASSES

  RATIOS = %w[%] # rubocop:disable Style/MutableConstant

  MASSES.each { |m| VOLUMES.each { |v| RATIOS << "#{m}/#{v}" } }

  before_validation do
    sanitize_whitespace
    self.generated_name = process_name.presence || "Unnamed Item"
  end

  def self.item_instances(item)
    PackedItem.where(item_id: item.id).count
  end

  def process_name
    [brand.to_s.titleize, object.titleize, standardized_size.to_s,
     package.to_s, numerical_1_phrase.to_s, numerical_2_phrase.to_s,
     concentration_phrase.to_s, area_phrase.to_s, range_phrase.to_s].reject(&:empty?).join(" ").squish
  end

  def numerical_1_phrase
    return if numerical_size_1.blank?

    strip_trailing_zero(numerical_size_1) + numerical_units_1.to_s + " #{numerical_description_1.to_s.titleize}"
  end

  def numerical_2_phrase
    return if numerical_size_2.blank?

    strip_trailing_zero(numerical_size_2) + numerical_units_2.to_s + " #{numerical_description_2.to_s.titleize}"
  end

  def concentration_phrase
    return if concentration.blank?

    strip_trailing_zero(concentration) + concentration_units.to_s + " #{concentration_description.to_s.titleize}"
  end

  def area_phrase
    return if area_1.blank? || area_2.blank?

    strip_trailing_zero(area_1) + "x" + strip_trailing_zero(area_2) + area_units.to_s + " #{area_description.to_s.titleize}"
  end

  def range_phrase
    return if range_1.blank? || range_2.blank?

    strip_trailing_zero(range_1) + "-" + strip_trailing_zero(range_2) + range_units.to_s + " #{range_description.to_s.titleize}"
  end

  def package
    return if packaged_quantity.blank?

    "#{packaged_quantity}-Pack"
  end

  def strip_trailing_zero(n)
    n.to_s.sub(/\.?0+$/, "")
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
