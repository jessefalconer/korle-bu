# frozen_string_literal: true

require "rails_helper"

describe PackedItem do
  let(:warehouse) { create :warehouse }

  def received_shipment(to: warehouse)
    create(:shipment, receiving_warehouse: to).tap { |s| s.update!(status: Shipment::RECEIVED) }
  end

  def packed_item(container:, quantity: 3)
    create :packed_item, box: nil, pallet: nil, shipment: nil, container: container, quantity: quantity
  end

  describe ".received_in" do
    let(:container) { create :container, shipment: received_shipment }
    let!(:in_stock) { packed_item(container: container) }

    it "includes unarchived items with stock in received shipments bound for the warehouse" do
      expect(PackedItem.received_in(warehouse.id)).to contain_exactly(in_stock)
    end

    it "excludes items with nothing remaining" do
      in_stock.update_columns(remaining_quantity: 0)

      expect(PackedItem.received_in(warehouse.id)).to be_empty
    end

    it "excludes archived items" do
      in_stock.update_columns(status: PackedItem::ARCHIVED)

      expect(PackedItem.received_in(warehouse.id)).to be_empty
    end

    it "excludes shipments bound for another warehouse" do
      packed_item(container: create(:container, shipment: received_shipment(to: create(:warehouse))))

      expect(PackedItem.received_in(warehouse.id)).to contain_exactly(in_stock)
    end

    it "excludes shipments that have not been received" do
      packed_item(container: create(:container, shipment: create(:shipment, receiving_warehouse: warehouse)))

      expect(PackedItem.received_in(warehouse.id)).to contain_exactly(in_stock)
    end

    it "excludes items with no shipment" do
      packed_item(container: create(:container, shipment: nil))

      expect(PackedItem.received_in(warehouse.id)).to contain_exactly(in_stock)
    end

    it "allows filtering and ordering on items columns" do
      category = create :category
      in_stock.item.update!(category: category)

      expect(PackedItem.received_in(warehouse.id).where(items: { category_id: category.id }).order("items.generated_name"))
        .to contain_exactly(in_stock)
    end
  end

  describe ".with_parents" do
    let(:shipment) { create :shipment }
    let(:container) { create :container, shipment: shipment }
    let(:pallet) { create :pallet, container: container }

    before do
      [
        { container: container },
        { pallet: pallet },
        { box: create(:box, pallet: pallet, container: nil) },
        { box: create(:box, container: container, pallet: nil) }
      ].each { |parents| create :packed_item, { box: nil, pallet: nil, container: nil, shipment: nil }.merge(parents) }
    end

    it "loads every parent the unpack forms read, so walking them runs no queries" do
      items = PackedItem.with_parents.to_a

      queries = count_queries do
        items.each do |pi|
          pi.location_name
          parent = pi.parent
          parent.shipment
          parent.container if parent.respond_to?(:container)
          parent.pallet&.container if parent.respond_to?(:pallet)
        end
      end

      expect(items.map { |pi| pi.parent.shipment }).to all(eq(shipment))
      expect(queries).to eq(0)
    end
  end
end
