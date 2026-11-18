# frozen_string_literal: true

require "rails_helper"

describe Warehouse do
  subject { create :warehouse }

  describe "validations" do
    it "is active by default" do
      expect(subject.status).to eq("Active")
      expect(subject).to be_active
    end

    it "rejects unknown statuses" do
      expect(build(:warehouse, status: "Closed")).not_to be_valid
    end
  end

  describe "#active?" do
    it "is false when deactivated" do
      subject.update(status: "Deactivated")
      expect(subject).not_to be_active
    end
  end

  describe "#full_address" do
    it "joins the address parts in order" do
      warehouse = build(:warehouse, street: "1 Guggisberg Ave", postal_code: "GA-123",
                                    city: "Accra", province: "Greater Accra", country: "Ghana")
      expect(warehouse.full_address).to eq("1 Guggisberg Ave, GA-123, Accra, Greater Accra, Ghana")
    end

    it "skips blank parts" do
      warehouse = build(:warehouse, street: "", city: "Accra", country: "Ghana")
      expect(warehouse.full_address).to eq("Accra, Ghana")
    end

    it "is empty when there is no address" do
      expect(build(:warehouse).full_address).to eq("")
    end
  end

  describe "shipment associations" do
    let(:other) { create :warehouse }

    it "separates shipments by status and direction" do
      received = create :shipment, receiving_warehouse: subject, shipping_warehouse: other
      received.update(status: Shipment::RECEIVED)
      in_progress = create :shipment, shipping_warehouse: subject, receiving_warehouse: other
      complete = create :shipment, shipping_warehouse: subject, receiving_warehouse: other
      complete.update(status: Shipment::COMPLETE)

      expect(subject.received_shipments).to contain_exactly(received)
      expect(subject.in_progress_shipments).to contain_exactly(in_progress)
      expect(subject.complete_shipments).to contain_exactly(complete)
    end
  end

  describe "#associations?" do
    it "is false for a fresh warehouse" do
      expect(subject.associations?).to be(false)
    end

    it "is true when users belong to it" do
      create :user, warehouse: subject
      expect(subject.associations?).to be(true)
    end

    it "is true when it is shipping an in-progress shipment" do
      create :shipment, shipping_warehouse: subject
      expect(subject.associations?).to be(true)
    end
  end
end
