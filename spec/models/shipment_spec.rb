# frozen_string_literal: true

require "rails_helper"

describe Shipment do
  subject { create :shipment, user: user }

  let(:user) { create :user }

  describe "initializes with a default name and custom UID" do
    it "with a name" do
      shipment = Shipment.new
      expect(shipment.name).to eq("SHIPMENT-1")
      expect(shipment.custom_uid).to eq(1)
      expect(shipment.status).to eq("In Progress")
    end
  end
end
