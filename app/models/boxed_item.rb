# frozen_string_literal: true

class BoxedItem < ApplicationRecord
  belongs_to :item, optional: false
  belongs_to :box, optional: false
  belongs_to :user, optional: false

  has_one :category, through: :item

  delegate :generated_name, to: :item

  def self.by_item
    all.group_by(&:item).each_with_object({}) do |(item, boxes), hash|
      hash[boxes.first.generated_name] = {category: item.category.name, quantity: boxes.sum(&:quantity)}
    end
  end

  def self.by_category
    all.group_by(&:category).each_with_object({}) do |(item, boxes), hash|
      hash[boxes.first&.category&.name || "N/A"] =
        boxes.group_by(&:item).each_with_object({}) { |(b,i), h| h[b.generated_name] = i.sum(&:quantity)}
    end
  end
end
