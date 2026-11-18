# frozen_string_literal: true

require "rails_helper"

describe PackedItem do
  subject { create :packed_item, user: user, box: box, item: item }

  let(:box) { create :box, pallet: pallet }
  let(:pallet) { create :pallet, container: container }
  let(:container) { create :container, shipment: shipment }
  let(:shipment) { create :shipment }
  let(:user) { create :user }
  let(:item) { create :item }

  describe "delegate naming" do
    it "has a name" do
      expect(subject.generated_name).to eq(item.generated_name)
    end
  end

  describe "parent assignments" do
    it "belongs to a shipment through associations" do
      expect(subject.shipment).to eq(shipment)
    end
  end

  describe "status validation" do
    it "requires a valid status when not assigned to a parent" do
      expect(build(:packed_item, box: nil, pallet: nil, container: nil, status: nil)).not_to be_valid
      expect(build(:packed_item, box: nil, pallet: nil, container: nil, status: "Lost")).not_to be_valid
      expect(build(:packed_item, box: nil, pallet: nil, container: nil, status: PackedItem::STAGED)).to be_valid
    end
  end

  describe "parent status" do
    it "takes on the status of its parent when saved" do
      box = create :box, pallet: nil, container: nil
      box.update(status: Box::COMPLETE)
      packed = create :packed_item, box: box, pallet: nil, container: nil, shipment: nil, status: nil

      expect(packed.status).to eq(Box::COMPLETE)
    end

    it "keeps its own status when unassigned" do
      packed = create :packed_item, box: nil, pallet: nil, container: nil, shipment: nil,
                                    status: PackedItem::WAREHOUSED
      expect(packed.reload.status).to eq(PackedItem::WAREHOUSED)
    end
  end

  describe "#remaining_quantity" do
    it "starts equal to the packed quantity" do
      packed = create :packed_item, box: nil, pallet: nil, container: nil, status: PackedItem::STAGED, quantity: 12
      expect(packed.remaining_quantity).to eq(12)
    end
  end

  describe "#location_name" do
    it "is the parent's name when assigned" do
      expect(subject.location_name).to eq(box.name)
    end

    it "is the status when unassigned" do
      packed = create :packed_item, box: nil, pallet: nil, container: nil, status: PackedItem::STAGED
      expect(packed.location_name).to eq(PackedItem::STAGED)
    end
  end

  describe "#parent" do
    it "prefers box, then pallet, then container" do
      expect(build(:packed_item, box: box, pallet: pallet, container: container).parent).to eq(box)
      expect(build(:packed_item, box: nil, pallet: pallet, container: container).parent).to eq(pallet)
      expect(build(:packed_item, box: nil, pallet: nil, container: container).parent).to eq(container)
    end
  end

  describe "scopes" do
    let!(:staged) { create :packed_item, box: nil, pallet: nil, container: nil, status: PackedItem::STAGED }
    let!(:warehoused) { create :packed_item, box: nil, pallet: nil, container: nil, status: PackedItem::WAREHOUSED }
    let!(:boxed) { subject }

    it "finds unassigned staged items" do
      expect(PackedItem.staged).to contain_exactly(staged)
    end

    it "finds unassigned warehoused items" do
      expect(PackedItem.warehoused).to contain_exactly(warehoused)
    end

    it "finds items with remaining inventory" do
      empty = create :packed_item, box: nil, pallet: nil, container: nil, status: PackedItem::STAGED, quantity: 0
      staged.update(quantity: 4)

      expect(PackedItem.with_inventory).to include(staged)
      expect(PackedItem.with_inventory).not_to include(empty)
    end
  end

  describe "reporting" do
    let(:category) { create :category, name: "Medical" }
    let(:categorized) { create :item, object: "Gauze", category: category }
    let(:uncategorized) { create :item, object: "Crutch" }
    let(:box_1) { create :box, pallet: nil, container: nil }
    let(:box_2) { create :box, pallet: nil, container: nil }

    before do
      create :packed_item, item: categorized, box: box_1, pallet: nil, container: nil, quantity: 5, weight: 1.5
      create :packed_item, item: categorized, box: box_2, pallet: nil, container: nil, quantity: 3, weight: nil
      create :packed_item, item: uncategorized, box: nil, pallet: nil, container: nil,
                           status: PackedItem::WAREHOUSED, quantity: 2, weight: 2.0
    end

    describe ".by_item" do
      it "totals quantity and weight per item with locations" do
        report = PackedItem.order(:id).by_item

        expect(report).to eq(
          "Gauze" => { category: "Medical", quantity: 8, weight: 1.5, location: "#{box_1.name}, #{box_2.name}" },
          "Crutch" => { category: "N/A", quantity: 2, weight: 2.0, location: PackedItem::WAREHOUSED }
        )
      end
    end

    describe ".by_category" do
      it "nests item totals under each category" do
        report = PackedItem.order(:id).by_category

        expect(report).to eq(
          "Medical" => { "Gauze" => { quantity: 8, weight: 1.5, location: "#{box_1.name}, #{box_2.name}" } },
          "N/A" => { "Crutch" => { quantity: 2, weight: 2.0, location: PackedItem::WAREHOUSED } }
        )
      end
    end
  end
end
