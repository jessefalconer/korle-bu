# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password
  paginates_per 10

  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, uniqueness: true
  validates :first_name, :last_name, presence: true

  def name
    first_name + " " + last_name
  end
end
