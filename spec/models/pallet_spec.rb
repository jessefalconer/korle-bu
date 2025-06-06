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

  describe "#cascade_statuses" do
    it "changes the status of child resources to the same status" do
      subject.update(status: Pallet::RECEIVED)
      expect(box.reload.status).to eq(Box::RECEIVED)

      subject.update(status: Pallet::ARCHIVED)
      expect(box.reload.status).to eq(Box::ARCHIVED)

      subject.update(status: Pallet::IN_PROGRESS)
      expect(box.reload.status).to eq(Box::IN_PROGRESS)

      subject.update(status: Pallet::COMPLETE)
      expect(box.reload.status).to eq(Box::COMPLETE)
    end

    it "does not change the status of boxes when the pallet is 'Warehoused'" do
      subject.update(status: Pallet::WAREHOUSED)
      expect(box.reload.status).to eq(Box::IN_PROGRESS)
    end

    it "does not change the status of boxes when the pallet is 'Staged'" do
      subject.update(status: Pallet::STAGED)
      expect(box.reload.status).to eq(Box::IN_PROGRESS)
    end
  end

  context "a pallet, with a box, has its status changed to 'Warehoused'" do
    it "dissassociates itself from the container, but the boxes are unchanged" do
      subject.update(status: Pallet::WAREHOUSED)
      expect(subject.boxes).to include(box)
      expect(box.reload.status).to eq(Box::IN_PROGRESS)
      expect(subject.container).to be_nil
    end
  end

  context "a pallet, with a box, has its status changed to 'Staged'" do
    it "dissassociates itself from the container, but the boxes are unchanged"  do
      subject.update(status: Pallet::STAGED)
      expect(subject.boxes).to include(box)
      expect(box.reload.status).to eq(Box::IN_PROGRESS)
      expect(subject.container).to be_nil
    end
  end

  describe "#adopt_status" do
    context "a pallet previously did not belong to a container and was status 'Warehoused'" do
      it "adopts the status of the container" do
        container.update(status: Container::IN_PROGRESS)
        subject.update(container: nil, status: Pallet::WAREHOUSED)
        subject.update(container: container)

        expect(subject.status).to eq(Container::IN_PROGRESS)
        expect(box.reload.status).to eq(Box::IN_PROGRESS)
      end
    end

    context "a pallet previously did not belong to a container and was status 'Staged'" do
      it "adopts the status of the container" do
        container.update(status: Container::IN_PROGRESS)
        subject.update(container: nil, status: Pallet::STAGED)
        subject.update(container: container)

        expect(subject.status).to eq(Container::IN_PROGRESS)
        expect(box.reload.status).to eq(Box::IN_PROGRESS)
      end
    end
  end
end
