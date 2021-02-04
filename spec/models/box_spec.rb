# frozen_string_literal: true

require "rails_helper"

describe Box do
  subject { create :box, user: user, pallet: pallet }
  let(:pallet) { create :pallet }
  let(:container) { create :container }

  let(:user) { create :user }

  describe "new" do
    it "initializes with defaults" do
      box = Box.new
      expect(box.name).to eq("BOX-1")
      expect(box.custom_uid).to eq(1)
      expect(box.status).to eq("In Progress")
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
end
