# frozen_string_literal: true

require "rails_helper"

describe Pallet do
  subject { create :pallet, user: user }

  let(:user) { create :user }

  describe "initializes with a default name and custom UID" do
    it "with a name" do
      pallet = Pallet.new
      expect(pallet.name).to eq("PALLET-1")
      expect(pallet.custom_uid).to eq(1)
      expect(pallet.status).to eq("In Progress")
    end
  end
end
