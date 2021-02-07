# frozen_string_literal: true

require "rails_helper"

describe Pallet do
  subject { create :pallet, user: user, container: container }
  let!(:box) { create :box, pallet: subject, user: user }
  let!(:container) { create :container, shipment: shipment, user: user }
  let!(:shipment) { create :shipment, user: user }

  let(:user) { create :user }

  describe "initializes with a default name and custom UID" do
    it "with a name" do
      expect(subject.name).to eq("PALLET-1")
      expect(subject.custom_uid).to eq(1)
      expect(subject.status).to eq("In Progress")
    end
  end

  describe "cascading statuses" do
    it "changes the status of child resources to the same status" do
      subject.update(status: Pallet::RECEIVED)
      expect(box.reload.status).to eq(Box::RECEIVED)
    end
  end
end
