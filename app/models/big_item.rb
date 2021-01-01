# frozen_string_literal: true

class BigItem < ApplicationRecord
  # This is a legacy class replaced by {PackedItem} and {Item}
  belongs_to :container, optional: false
  belongs_to :item, optional: false
end
