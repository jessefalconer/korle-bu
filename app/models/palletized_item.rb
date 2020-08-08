# frozen_string_literal: true

class PalletizedItem < ApplicationRecord
  belongs_to :item, optional: false
  belongs_to :pallet, optional: false
end
