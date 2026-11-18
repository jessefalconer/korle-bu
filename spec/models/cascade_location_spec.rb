# frozen_string_literal: true

require "rails_helper"

# When a box, pallet or container moves or changes status, its packed items must
# take the parent's status and the shipment of the parent chain.
describe "Cascading packed item status and shipment" do
  let(:shipment_a) { create :shipment }
  let(:shipment_b) { create :shipment }
  let(:container_a) { create :container, shipment: shipment_a }
  let(:container_b) { create :container, shipment: shipment_b }

  def packed_item(**parents)
    create :packed_item, { box: nil, pallet: nil, container: nil, shipment: nil, quantity: 2 }.merge(parents)
  end

  describe "moving a box" do
    let(:pallet) { create :pallet, container: container_a }
    let(:box) { create :box, pallet: pallet, container: nil }
    let!(:item) { packed_item(box: box) }

    it "starts in the pallet's shipment" do
      expect(item.reload.shipment).to eq(shipment_a)
    end

    it "moves its items to the new container's shipment" do
      box.reload.update!(container: container_b)

      expect(item.reload.shipment).to eq(shipment_b)
      expect(item.status).to eq(box.reload.status)
    end

    it "clears its items' shipment when orphaned by staging" do
      box.reload.update!(status: Box::STAGED)

      expect(box.reload.parent).to be_nil
      expect(item.reload).to have_attributes(shipment_id: nil, status: PackedItem::STAGED)
    end

    it "keeps remaining quantity intact" do
      box.reload.update!(container: container_b)

      expect(item.reload.remaining_quantity).to eq(2)
    end
  end

  describe "moving a pallet" do
    let(:pallet) { create :pallet, container: container_a }
    let(:box) { create :box, pallet: pallet, container: nil }
    let!(:pallet_item) { packed_item(pallet: pallet) }
    let!(:box_item) { packed_item(box: box) }

    it "moves pallet items and boxed items to the new shipment" do
      pallet.reload.update!(container: container_b)

      expect(pallet_item.reload.shipment).to eq(shipment_b)
      expect(box_item.reload.shipment).to eq(shipment_b)
    end

    it "gives boxed items their box's status, and pallet items the pallet's status" do
      pallet.reload.update!(status: Pallet::COMPLETE)

      expect(pallet_item.reload.status).to eq(PackedItem::COMPLETE)
      expect(box.reload.status).to eq(Box::COMPLETE)
      expect(box_item.reload.status).to eq(PackedItem::COMPLETE)
    end
  end

  describe "moving a container" do
    let(:pallet) { create :pallet, container: container_a }
    let(:pallet_box) { create :box, pallet: pallet, container: nil }
    let(:container_box) { create :box, container: container_a, pallet: nil }
    let!(:items) do
      [
        packed_item(container: container_a),
        packed_item(pallet: pallet),
        packed_item(box: pallet_box),
        packed_item(box: container_box)
      ]
    end

    it "moves every nested item to the new shipment" do
      container_a.reload.update!(shipment: shipment_b)

      expect(items.map { |i| i.reload.shipment }).to all(eq(shipment_b))
    end

    it "clears every nested item's shipment when removed from a shipment" do
      container_a.reload.update!(shipment: nil)

      expect(items.map { |i| i.reload.shipment_id }).to all(be_nil)
    end

    it "cascades a received status to every nested item" do
      container_a.reload.update!(status: Container::RECEIVED)

      expect(items.map { |i| i.reload.status }).to all(eq(PackedItem::RECEIVED))
    end
  end

  # Each example runs the same change twice, putting things back in between, with more
  # packed items the second time. The query count must not grow with the item count.
  describe "query counts" do
    before do
      container_a
      container_b
    end

    def expect_constant_queries(change:, undo:, add_item:)
      add_item.call
      baseline = count_queries(&change)
      undo.call

      3.times { add_item.call }
      expect(count_queries(&change)).to eq(baseline)
    end

    it "moves a box without a query per packed item" do
      pallet = create :pallet, container: container_a
      box = create :box, pallet: pallet, container: nil

      expect_constant_queries(
        change: -> { Box.find(box.id).update!(container: container_b) },
        undo: -> { Box.find(box.id).update!(pallet: pallet) },
        add_item: -> { packed_item(box: box) }
      )
    end

    it "moves a pallet without a query per packed item" do
      pallet = create :pallet, container: container_a
      box = create :box, pallet: pallet, container: nil

      expect_constant_queries(
        change: -> { Pallet.find(pallet.id).update!(container: container_b) },
        undo: -> { Pallet.find(pallet.id).update!(container: container_a) },
        add_item: -> { packed_item(pallet: pallet) && packed_item(box: box) }
      )
    end

    it "moves a container without a query per packed item" do
      expect_constant_queries(
        change: -> { Container.find(container_a.id).update!(shipment: shipment_b) },
        undo: -> { Container.find(container_a.id).update!(shipment: shipment_a) },
        add_item: -> { packed_item(container: container_a) }
      )
    end

    it "cascades a container status without a query per packed item" do
      expect_constant_queries(
        change: -> { Container.find(container_a.id).update!(status: Container::RECEIVED) },
        undo: -> { Container.find(container_a.id).update!(status: Container::COMPLETE) },
        add_item: -> { packed_item(container: container_a) }
      )
    end
  end
end
