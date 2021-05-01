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
end
