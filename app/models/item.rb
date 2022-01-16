# frozen_string_literal: true

class Item < ApplicationRecord
  include PgSearch::Model

  paginates_per 35

  pg_search_scope :search_by_generated_name,
                  against: :generated_name,
                  using: {
                    tsearch: {
                      prefix: true,
                      any_word: true,
                      dictionary: "english",
                    },
                    trigram: {}
                  },
                  ranked_by: ":trigram"

  belongs_to :user, optional: false
  belongs_to :category, optional: true

  has_many :packed_items, dependent: :destroy

  has_one_attached :photo

  scope :unverified, -> { where(verified: false) }
  scope :verified, -> { where(verified: true) }
  scope :uncategorized, -> { where(category: nil) }
  scope :categorized, -> { where.not(category: nil) }
  scope :flagged, -> { where(flagged: true) }
  scope :not_flagged, -> { where(flagged: false) }

  validates :generated_name, uniqueness: true # rubocop:disable Rails/UniqueValidationWithoutIndex

  before_validation do
    self.generated_name = generated_name.squish
  end

  def self.find_similar_records(item)
    Item.search_by_generated_name(item.generated_name).where.not(id: item.id)
  end

  def self.execute_merge(item, merge_items, delete: false, verify: true)
    merge_items.each do |merge_item|
      PackedItem.where(item_id: merge_item.id).update_all(item_id: item.id) # rubocop:disable Rails/SkipsModelValidations#

      Item.find(merge_item.id).destroy if delete
      Item.find(item.id).update(verified: verify) if verify
    end
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
end
