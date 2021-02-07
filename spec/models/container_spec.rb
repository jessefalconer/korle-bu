# frozen_string_literal: true

require "rails_helper"

describe Container do
  subject { create :container, user: user, shipment: shipment }
  let!(:box) { create :box, pallet: pallet, user: user }
  let!(:pallet) { create :pallet, container: subject, user: user }
  let!(:shipment) { create :shipment, user: user }

  let(:user) { create :user }

  describe "initializes with a default name and custom UID" do
    it "with a name" do
      expect(subject.name).to eq("CONTAINER-1")
      expect(subject.custom_uid).to eq(1)
      expect(subject.status).to eq("In Progress")
    end
  end

  describe "cascading statuses" do
    it "changes the status of child resources to the same status" do
      subject.update(status: Container::RECEIVED)
      expect(pallet.reload.status).to eq(Pallet::RECEIVED)
      expect(box.reload.status).to eq(Box::RECEIVED)
    end
  end
end
