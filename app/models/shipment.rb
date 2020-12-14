# frozen_string_literal: true

class Shipment < ApplicationRecord
  require "csv"

  STATUSES = ["Not Started", "In Progress", "Ready to Ship", "In Transit", "Received"].freeze

  belongs_to :user, optional: false
  belongs_to :receiving_warehouse, class_name: "Warehouse", optional: false
  belongs_to :shipping_warehouse, class_name: "Warehouse", optional: false

  has_many :containers, dependent: :nullify
  has_many :pallets, through: :containers
  has_many :boxes, through: :pallets

  validates :name, :custom_uid, :user, presence: true
  validates :custom_uid, :name, uniqueness: true
  validates :status, inclusion: { in: STATUSES }

  paginates_per 10

  def to_csv
    attributes = %w[id name status custom_uid]

    CSV.generate(headers: true) do |csv|
      csv << attributes

      csv << ["PALLETS"]
      pallets.each do |pallet|
        csv << attributes.map{ |attr| pallet.send(attr) }
        csv << ["BOXES"]
        pallet.boxes.each do |box|
          csv << attributes.map{ |attr| box.send(attr) }
        end
      end
    end
  end
end
