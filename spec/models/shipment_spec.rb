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
end
