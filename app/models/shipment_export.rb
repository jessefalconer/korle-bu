# frozen_string_literal: true

class ShipmentExport
  include ActiveModel::Model
  require "csv"

  attr_accessor :group_by

  def initialize(id, group_by = "item")
    @shipment = Shipment.find(id)
    @group_by = group_by
  end

  def to_csv
    CSV.generate(headers: true) do |csv|
      case @group_by
      when "category"
        csv << %w[Category Item Item\ Quantity Item\ Weight\ (kg) Locations]
        generate_by_category(@shipment.packed_items, csv)
      when "item"
        csv << %w[Item Item\ Quantity Category Item\ Weight\ (kg) Locations]
        generate_by_item(@shipment.packed_items, csv)
      else
        csv << ["Error generating CSV"]
      end
    end
  end

  def generate_by_category(collection, csv)
    collection.by_category.sort.each do |category, items|
      csv << [category, "-", "-", "-", "-"]
      items.sort.each do |item, values|
        csv << ["-", item, values[:quantity], values[:weight], values[:location]]
      end
    end
  end

  def generate_by_item(collection, csv)
    collection.by_item.sort.each do |item, values|
      csv << [item, values[:quantity], values[:category], values[:weight], values[:location]]
    end
  end
end
