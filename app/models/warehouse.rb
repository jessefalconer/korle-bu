# frozen_string_literal: true

class Warehouse < ApplicationRecord
  STATUSES = %w[Active Deactivated Other].freeze
  paginates_per 10
  belongs_to :user, optional: false
end
