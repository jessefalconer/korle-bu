# frozen_string_literal: true

require "rails_helper"

describe UnpackingEvent do
  subject { create :unpacking_event, user: user, packed_item: boxed_item, hospital: hospital }

  let(:boxed_item) { create :packed_item, item: item, user: user, box: box, quantity: 10, remaining_quantity: 10 }
  let(:box) { create :box, user: user }
  let(:item) { create :item, user: user }
  let(:user) { create :user }
  let(:hospital) { create :hospital }

  describe "delegate naming" do
    it "has a name" do
      expect(subject.generated_name).to eq(item.generated_name)
    end
  end

  describe "unpacking quantities" do
    it "deducts quantities against the packed item amount" do
      subject.update(quantity: 5)
      expect(boxed_item.remaining_quantity).to eq(5)
    end

    it "doesn't tamper with the original, shipped amount" do
      subject.update(quantity: 5)
      expect(boxed_item.quantity).to eq(10)
    end
  end

  describe "quantity checks" do
    def unpack(quantity, item: boxed_item)
      build :unpacking_event, user: user, packed_item: item, hospital: hospital, quantity: quantity
    end

    it "rejects zero, negative and fractional quantities" do
      expect(unpack(0)).not_to be_valid
      expect(unpack(-3)).not_to be_valid
      expect(unpack(1.5)).not_to be_valid
    end

    it "rejects more than what is left, counting earlier unpacks" do
      unpack(7).save!

      extra = unpack(4)
      expect(extra).not_to be_valid
      expect(extra.errors[:quantity]).to include("can't be more than the 3 remaining")
      expect(unpack(3)).to be_valid
    end

    it "lets an event's own quantity be edited within what is left" do
      event = unpack(6).tap(&:save!)

      expect(event.update(quantity: 10)).to be(true)
      expect(event.update(quantity: 11)).to be(false)
    end

    it "still lets old zero-quantity events have their timestamp edited" do
      event = unpack(1).tap(&:save!)
      event.update_columns(quantity: 0)

      expect(event.reload.update(timestamp: 1.day.ago)).to be(true)
    end

    it "fills in a blank timestamp" do
      event = unpack(1)
      event.timestamp = nil
      event.save!

      expect(event.timestamp).to be_within(1.minute).of(Time.current)
    end
  end
end
