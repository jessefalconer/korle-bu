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
end
