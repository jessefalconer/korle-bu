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
        csv << ["Category", "Item", "Item Quantity", "Item Weight (kg)", "Locations"]
        generate_by_category(packed_items, csv)
      when "item"
        csv << ["Item", "Item Quantity", "Category", "Item Weight (kg)", "Locations"]
        generate_by_item(packed_items, csv)
      else
        csv << ["Error generating CSV"]
      end
    end
  end

  def generate_by_category(collection, csv)
    collection.by_category.sort.each do |category, items|
      csv << CsvSafety.row([category, "-", "-", "-", "-"])
      items.sort.each do |item, values|
        csv << CsvSafety.row(["-", item, values[:quantity], values[:weight], values[:location]])
      end
    end
  end

  def generate_by_item(collection, csv)
    collection.by_item.sort.each do |item, values|
      csv << CsvSafety.row([item, values[:quantity], values[:category], values[:weight], values[:location]])
    end
  end

  private

  # Everything the rows read (item, category, location) loaded up front: a few
  # queries, rather than three or more per packed line.
  def packed_items
    @shipment.packed_items.preload(:box, :pallet, :container, item: :category)
  end
end
