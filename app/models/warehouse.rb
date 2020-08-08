# frozen_string_literal: true

class Warehouse < ApplicationRecord
  STATUSES = %w[Active Deactivated Other].freeze
  belongs_to :user, optional: false
end
