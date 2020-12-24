# frozen_string_literal: true

module Exportable
  extend ActiveSupport::Concern

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
