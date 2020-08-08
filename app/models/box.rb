# frozen_string_literal: true

class Box < ApplicationRecord
  belongs_to :user, optional: false
  # TODO: these optional trues are status=unassigned
  belongs_to :container, optional: true
  belongs_to :pallet, optional: true

  has_many :boxed_items
end
