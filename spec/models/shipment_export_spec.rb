# frozen_string_literal: true

require "rails_helper"

describe ShipmentExport do
  let(:shipment) { create :shipment }
  let(:container) { create :container, shipment: shipment }
  let(:box) { create :box, container: container, pallet: nil }
  let(:category) { create :category, name: "Medical" }
  let(:gauze) { create :item, object: "Gauze", category: category }
  let(:crutch) { create :item, object: "Crutch" }

  before do
    create :packed_item, item: gauze, container: container, box: nil, pallet: nil, quantity: 5, weight: 1.5
    create :packed_item, item: gauze, box: box, container: nil, pallet: nil, quantity: 2, weight: 0.5
    create :packed_item, item: crutch, container: container, box: nil, pallet: nil, quantity: 1, weight: nil
    # Not part of the shipment
    create :packed_item, item: crutch, box: nil, pallet: nil, container: nil, status: PackedItem::WAREHOUSED, quantity: 9
  end

  def rows(group_by)
    CSV.parse(ShipmentExport.new(shipment.id, group_by).to_csv)
  end

  it "groups by item by default" do
    expect(ShipmentExport.new(shipment.id).group_by).to eq("item")
  end

  describe "grouped by item" do
    it "lists each item with totals, sorted by name" do
      header, *body = rows("item")

      expect(header).to eq(["Item", "Item Quantity", "Category", "Item Weight (kg)", "Locations"])
      expect(body).to eq([
        ["Crutch", "1", "N/A", "0", container.name],
        ["Gauze", "7", "Medical", "2.0", "#{container.name}, #{box.name}"]
      ])
    end
  end

  describe "grouped by category" do
    it "lists categories with their items beneath" do
      header, *body = rows("category")

      expect(header).to eq(["Category", "Item", "Item Quantity", "Item Weight (kg)", "Locations"])
      expect(body).to eq([
        ["Medical", "-", "-", "-", "-"],
        ["-", "Gauze", "7", "2.0", "#{container.name}, #{box.name}"],
        ["N/A", "-", "-", "-", "-"],
        ["-", "Crutch", "1", "0", container.name]
      ])
    end
  end

  describe "with an unknown grouping" do
    it "returns an error row" do
      expect(rows("weight")).to eq([["Error generating CSV"]])
    end
  end
end
