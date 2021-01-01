# frozen_string_literal: true

class PalletizedItem < ApplicationRecord
  belongs_to :item, optional: false
  belongs_to :pallet, optional: false
  belongs_to :user, optional: false

  has_one :category, through: :item

  delegate :generated_name, to: :item

  def self.by_item
    all.group_by(&:item).each_with_object({}) do |(item, pallets), hash|
      hash[pallets.first.generated_name] = {category: item.category.name, quantity: pallets.sum(&:quantity)}
    end
  end

  def self.by_category
    all.group_by(&:category).each_with_object({}) do |(item, pallets), hash|
      hash[pallets.first&.category&.name || "N/A"] =
        pallets.group_by(&:item).each_with_object({}) { |(b,i), h| h[b.generated_name] = i.sum(&:quantity)}
    end
  end
end
