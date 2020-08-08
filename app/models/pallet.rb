# frozen_string_literal: true

class Pallet < ApplicationRecord
  belongs_to :user, optional: false
  # TODO: this optional true is status=unassigned
  belongs_to :container, optional: true
  has_many :boxes
  has_many :palletized_items
end
