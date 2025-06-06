# frozen_string_literal: true

require "rails_helper"

describe Box do
  subject { create :box, user: user, pallet: pallet }
  let!(:pallet) { create :pallet, user: user }
  let!(:container) { create :container, shipment: shipment, user: user }
  let!(:shipment) { create :shipment, user: user }
  let!(:box_item) { create :packed_item, box: subject, user: user }

  let(:user) { create :user }

  describe "new" do
    it "initializes with defaults" do
      expect(subject.name).to eq("BOX-1")
      expect(subject.custom_uid).to eq(1)
      expect(subject.status).to eq("In Progress")
    end
  end

  describe "parent assignments" do
    it "belongs to either a pallet or container" do
      expect(subject.pallet).to be_present

      subject.update(container: container)
      expect(subject.container).to be_present
      expect(subject.pallet).not_to be_present
    end
  end

  describe "#parent" do
    it "returns the parent container or pallet" do
      expect(subject.parent).to eq(pallet)

      subject.update(container: container, pallet: nil)
      expect(subject.parent).to eq(container)
    end
  end

  describe "#cascade_statuses" do
    it "changes the status of child resources to the same status" do
      subject.update(status: Box::RECEIVED)
      expect(box_item.reload.status).to eq(PackedItem::RECEIVED)

      subject.update(status: Box::ARCHIVED)
      expect(box_item.reload.status).to eq(PackedItem::ARCHIVED)

      subject.update(status: Box::IN_PROGRESS)
      expect(box_item.reload.status).to eq(PackedItem::IN_PROGRESS)

      subject.update(status: Box::COMPLETE)
      expect(box_item.reload.status).to eq(PackedItem::COMPLETE)
    end
  end

  describe "orphaning - pallet parent" do
    context "when a box's status is changed to warehoused or staged, and its pallet is not" do
      it "removes the association with the parent" do
        subject.update(status: Box::COMPLETE)
        expect(subject.parent).to be_present

        subject.update(status: Box::WAREHOUSED)
        expect(subject.parent).to be_nil
      end
    end

    context "when a box's status is changed to warehoused or staged, and its pallet is also warehoused or staged" do
      it "does not remove the association with the parent" do
        subject.parent.update(status: Box::WAREHOUSED)
        expect(subject.parent).to be_present

        subject.parent.update(status: Box::STAGED)
        expect(subject.parent).to be_present
      end
    end
  end

  describe "orphaning - container parent" do
    context "when a box's status is changed to warehoused or staged, and its container is not" do
      it "removes the association with the parent" do
        subject.update(pallet: nil, container: container)
        subject.update(status: Box::COMPLETE)
        expect(subject.parent).to be_present

        subject.update(status: Box::WAREHOUSED)
        expect(subject.parent).to be_nil
      end
    end

    context "when a box's status is changed to warehoused or staged, and its container is also warehoused or staged" do
      it "does not remove the association with the parent" do
        subject.update(pallet: nil, container: container)
        subject.parent.update(status: Box::WAREHOUSED)
        expect(subject.parent).to be_present

        subject.parent.update(status: Box::STAGED)
        expect(subject.parent).to be_present
      end
    end
  end

  describe "adopting status" do
    context "when a box had no parent" do
      it "adopts the status of its parent" do
        subject.update(pallet: nil, container: nil, status: Box::WAREHOUSED)
        container.update(status: Container::IN_PROGRESS)

        subject.update(container: container)
        expect(subject.status).to eq(Container::IN_PROGRESS)
      end
    end

    context "when a box has no parent, but it had a status not Warehoused or Staged" do
      it "does not adopt the status of its parent" do
        subject.update(pallet: nil, container: nil, status: Box::IN_PROGRESS)
        container.update(status: Container::COMPLETE)

        subject.update(container: container)
        expect(subject.status).to eq(Box::IN_PROGRESS)
      end
    end

    context "when a box has no parent, but it had a status Warehoused or Staged" do
      it "adopts the status of its parent" do
        subject.update(pallet: nil, container: nil, status: Box::WAREHOUSED)
        container.update(status: Container::IN_PROGRESS)

        subject.update(container: container)
        expect(subject.status).to eq(Box::IN_PROGRESS)
      end
    end
  end
end
