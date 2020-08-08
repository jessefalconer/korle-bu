# frozen_string_literal: true

class BoxedItem < ApplicationRecord
  belongs_to :item, optional: false
  belongs_to :box, optional: false
end
