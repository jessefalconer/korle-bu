# frozen_string_literal: true

class ItemBox < ApplicationRecord
  # This is a legacy class replaced by {PackedItem}
  belongs_to :box, optional: false
  belongs_to :item, optional: false
end
