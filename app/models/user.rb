# frozen_string_literal: true

class User < ApplicationRecord
  STATUSES = %w[Active Deactivated].freeze
  ROLES = %w[Volunteer Shipping\ Manager Admin Receiving\ Manager].freeze

  has_secure_password
  paginates_per 10

  has_many :shipments
  has_many :containers
  has_many :container_items
  has_many :pallets
  has_many :pallet_items
  has_many :boxes
  has_many :box_items

  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, uniqueness: true
  validates :first_name, :last_name, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :role, inclusion: { in: ROLES }

  def name
    "#{first_name} #{last_name}"
  end

  def volunteer?
    role == "Volunteer"
  end

  def shipping_manager?
    role == "Shipping Manager"
  end

  def admin?
    role == "Manager"
  end

  def receiving_manager?
    role == "Receiving Manager"
  end
end
