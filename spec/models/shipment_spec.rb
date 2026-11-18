# frozen_string_literal: true

require "rails_helper"

describe Shipment do
  subject { create :shipment, user: user }
  let!(:box) { create :box, pallet: pallet, user: user }
  let!(:pallet) { create :pallet, container: container, user: user }
  let!(:container) { create :container, shipment: subject, user: user }

  let(:user) { create :user }

  describe "initializes with a default name and custom UID" do
    it "with a name" do
      expect(subject.name).to eq("SHIPMENT-1")
      expect(subject.custom_uid).to eq(1)
      expect(subject.status).to eq(Shipment::IN_PROGRESS)
    end
  end

  describe "cascading statuses" do
    it "changes the status of child resources to the same status" do
      subject.update(status: Shipment::RECEIVED)
      expect(container.reload.status).to eq(Container::RECEIVED)
      expect(pallet.reload.status).to eq(Pallet::RECEIVED)
      expect(box.reload.status).to eq(Box::RECEIVED)
    end
  end

  describe "#packed_item_stats" do
    it "summarizes packed items in one query" do
      shipment = create :shipment
      container = create :container, shipment: shipment
      item = create :item
      [
        { item: item, quantity: 2, weight: 1.5, expiry_date: Date.new(2027, 5, 1) },
        { item: item, quantity: 3, weight: nil, expiry_date: nil },
        { item: create(:item), quantity: 4, weight: 0.25, expiry_date: Date.new(2026, 12, 1) }
      ].each { |attrs| create :packed_item, box: nil, pallet: nil, shipment: nil, container: container, **attrs }

      stats = nil
      shipment.reload
      expect(count_queries { stats = shipment.packed_item_stats }).to eq(1)
      expect(stats).to eq(
        unique_items: 2, instances: 3, quantity: 9, weight: 1.75,
        earliest_expiry: Date.new(2026, 12, 1), latest_expiry: Date.new(2027, 5, 1)
      )
    end

    it "handles a shipment with no packed items" do
      expect(create(:shipment).packed_item_stats).to eq(
        unique_items: 0, instances: 0, quantity: 0, weight: 0.0, earliest_expiry: nil, latest_expiry: nil
      )
    end
  end
end
