# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password
  paginates_per 10

  has_many :shipments
  has_many :containers
  has_many :containerized_items
  has_many :pallets
  has_many :palletized_items
  has_many :boxes
  has_many :boxed_items

  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, uniqueness: true
  validates :first_name, :last_name, presence: true

  def name
    first_name + " " + last_name
  end
end
