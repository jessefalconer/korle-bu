# frozen_string_literal: true

class Warehouse < ApplicationRecord
  STATUSES = %w[Active Deactivated].freeze

  belongs_to :user

  has_many :users

  paginates_per 25

  def active?
    status == "Active"
  end
end
