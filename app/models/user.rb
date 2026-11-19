# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password

  STATUSES = %w[Active Deactivated].freeze
  ROLES = ["Volunteer", "Shipping Manager", "Admin", "Receiving Manager"].freeze
  # Applies whenever a password is set or changed. Existing passwords are only
  # stored as hashes and are never re-validated, so shorter old ones keep working.
  MIN_PASSWORD_LENGTH = 8

  belongs_to :warehouse, optional: true

  has_many :shipments
  has_many :containers
  has_many :container_items, through: :containers
  has_many :pallets
  has_many :pallet_items, through: :pallets
  has_many :boxes
  has_many :box_items, through: :boxes
  has_many :packed_items
  has_many :warehouses
  has_many :items

  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, uniqueness: true, on: %i[create update] # rubocop:disable Rails/UniqueValidationWithoutIndex
  validates :phone, format: { with: /\A(?:\+?\d{1,3}\s*-?)?\(?(?:\d{3})?\)?[- ]?\d{3}[- ]?\d{4}\z/ }
  validates :first_name, :last_name, presence: true, on: %i[create update]
  validates :status, inclusion: { in: STATUSES }, on: %i[create update]
  validates :role, inclusion: { in: ROLES }, on: %i[create update]
  validates :password, length: { minimum: MIN_PASSWORD_LENGTH }, allow_nil: true

  paginates_per 25

  def name
    "#{first_name} #{last_name}"
  end

  ROLES.each do |user_role|
    define_method("#{user_role.parameterize(separator: "_")}?") do
      role == user_role
    end
  end

  def active?
    status == "Active"
  end

  def selectable_statuses(klass)
    return klass::STATUSES if admin?

    klass::STATUSES - [klass::ARCHIVED]
  end

  def created_records?
    reflections = User.reflections.select do |_association_name, reflection|
      reflection.macro == :has_many
    end

    reflections.keys.map do |assoc|
      send(assoc).any?
    end.any?(true)
  end
end
