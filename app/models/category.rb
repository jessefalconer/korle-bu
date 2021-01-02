# frozen_string_literal: true

class Category < ApplicationRecord
  belongs_to :user, optional: false

  has_many :items

  paginates_per 25
end
