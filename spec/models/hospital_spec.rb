# frozen_string_literal: true

require "rails_helper"

describe Hospital do
  subject { create :hospital, name: "Korle Bu Teaching Hospital" }

  describe "validations" do
    it "is active by default" do
      expect(subject).to be_active
    end

    it "requires a name" do
      expect(build(:hospital, name: nil)).not_to be_valid
    end

    it "requires a unique name" do
      subject
      expect(build(:hospital, name: "Korle Bu Teaching Hospital")).not_to be_valid
    end

    it "requires a warehouse" do
      expect(build(:hospital, warehouse: nil)).not_to be_valid
    end

    it "rejects unknown statuses" do
      expect(build(:hospital, status: "Closed")).not_to be_valid
    end
  end

  describe "#active?" do
    it "is false when deactivated" do
      subject.update(status: Hospital::DEACTIVATED)
      expect(subject).not_to be_active
    end
  end

  describe "#full_address" do
    it "joins non-blank address parts" do
      hospital = build(:hospital, street: "Guggisberg Ave", postal_code: nil, city: "Accra", country: "Ghana")
      expect(hospital.full_address).to eq("Guggisberg Ave, Accra, Ghana")
    end
  end

  describe "#users" do
    it "returns the users of its warehouse" do
      staff = create :user, warehouse: subject.warehouse
      create :user

      expect(subject.users).to contain_exactly(staff)
    end
  end
end
