# frozen_string_literal: true

require "rails_helper"

# `with_location` must load everything the box and pallet tables and presenters read,
# so walking from a record to its receiving warehouse runs no further queries.
describe "with_location scopes" do
  let(:shipment) { create :shipment }
  let(:container) { create :container, shipment: shipment }
  let(:pallet) { create :pallet, container: container }

  describe Box do
    before do
      create :box, pallet: pallet, container: nil
      create :box, container: container, pallet: nil
    end

    it "preloads the parent chain up to the receiving warehouse" do
      boxes = Box.with_location.to_a

      queries = count_queries do
        boxes.each do |box|
          box.pallet&.container
          box.shipment&.receiving_warehouse&.name
        end
      end

      expect(boxes.map { |b| b.shipment&.receiving_warehouse }).to all(eq(shipment.receiving_warehouse))
      expect(queries).to eq(0)
    end
  end

  describe Pallet do
    before do
      create :box, pallet: pallet, container: nil
      create :pallet, container: create(:container, shipment: create(:shipment))
    end

    it "preloads boxes and the parent chain up to the receiving warehouse" do
      pallets = Pallet.with_location.to_a

      queries = count_queries do
        pallets.each do |p|
          p.boxes.size
          p.shipment&.receiving_warehouse&.name
        end
      end

      expect(Pallet.with_location.find(pallet.id).boxes.size).to eq(1)
      expect(queries).to eq(0)
    end
  end
end
