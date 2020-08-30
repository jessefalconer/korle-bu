# frozen_string_literal: true

class Item < ApplicationRecord
  include PgSearch::Model

  paginates_per 10

  pg_search_scope :search_by_generated_name, against: [:generated_name],
    using: {
      tsearch: { prefix: true }
    }

  belongs_to :user, optional: false
  belongs_to :category, optional: true

  has_many :boxed_items, dependent: :destroy
  has_many :palletized_items, dependent: :destroy
  has_many :containerized_items, dependent: :destroy

  has_one_attached :photo

  STANDARD_SIZES = %w[XXXS XXS XS S M L XL XL XXL Assorted].freeze
  VOLUMES = %w[mL dL L floz cc qt pt gal].freeze
  LENGTHS = %w[nm μm mm cm m km ga in ft].freeze
  MASSES = %w[ng μg mg g kg lb oz mmol mol].freeze

  UNITS = VOLUMES + LENGTHS + MASSES

  RATIOS = %w[%] # rubocop:disable Style/MutableConstant

  MASSES.each { |m| VOLUMES.each { |v| RATIOS << "#{m}/#{v}" } }

  after_validation do
    sanitize_whitespace
    self.generated_name = process_name.presence || "Unnamed Item"
  end

  def process_name
    [brand.to_s.titleize, object.titleize, standardized_size.to_s,
     package.to_s, numerical_1_phrase.to_s, numerical_2_phrase.to_s,
     concentration_phrase.to_s].reject(&:empty?).join(" ").squish
  end

  def numerical_1_phrase
    return if numerical_size_1.blank?

    numerical_size_1.to_s + numerical_units_1.to_s + " #{numerical_description_1.to_s.titleize}"
  end

  def numerical_2_phrase
    return if numerical_size_2.blank?

    numerical_size_2.to_s + numerical_units_2.to_s + " #{numerical_description_2.to_s.titleize}"
  end

  def concentration_phrase
    return if concentration.blank?

    concentration.to_s + concentration_units.to_s + " #{concentration_description.to_s.titleize}"
  end

  def package
    return if packaged_quantity.blank?

    "#{packaged_quantity}-Pack"
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
