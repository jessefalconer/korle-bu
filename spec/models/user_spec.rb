# frozen_string_literal: true

require "rails_helper"

describe User do
  subject { create :user, first_name: "Ama", last_name: "Mensah" }

  describe "defaults" do
    it "is a deactivated volunteer by default" do
      expect(subject.status).to eq("Deactivated")
      expect(subject.role).to eq("Volunteer")
      expect(subject).not_to be_active
    end
  end

  describe "validations" do
    it "is valid from the factory" do
      expect(build(:user)).to be_valid
    end

    it "requires a well formed email" do
      expect(build(:user, email: "not-an-email")).not_to be_valid
    end

    it "requires a unique email" do
      create :user, email: "dupe@kbnf.org"
      expect(build(:user, email: "dupe@kbnf.org")).not_to be_valid
    end

    it "requires a first and last name" do
      expect(build(:user, first_name: nil)).not_to be_valid
      expect(build(:user, last_name: "")).not_to be_valid
    end

    it "accepts common phone formats" do
      ["1234567890", "123-456-7890", "(123) 456-7890", "+1 123-456-7890"].each do |phone|
        expect(build(:user, phone: phone)).to be_valid, "expected #{phone} to be valid"
      end
    end

    it "rejects malformed phone numbers" do
      ["abc", "12345", "123-45-678"].each do |phone|
        expect(build(:user, phone: phone)).not_to be_valid, "expected #{phone} to be invalid"
      end
    end

    it "rejects unknown statuses and roles" do
      expect(build(:user, status: "Suspended")).not_to be_valid
      expect(build(:user, role: "Overlord")).not_to be_valid
    end

    it "requires a password of at least 6 characters on create" do
      expect(build(:user, password: "12345")).not_to be_valid
      expect(build(:user, password: "123456")).to be_valid
    end

    it "does not require the password when updating other attributes" do
      persisted = User.find(subject.id)
      expect(persisted.update(first_name: "Kofi")).to be(true)
    end
  end

  describe "#name" do
    it "joins first and last name" do
      expect(subject.name).to eq("Ama Mensah")
    end
  end

  describe "role predicates" do
    it "defines a predicate for each role" do
      User::ROLES.each do |role|
        user = build(:user, role: role)
        predicate = "#{role.parameterize(separator: "_")}?"

        expect(user.public_send(predicate)).to be(true)
        (User::ROLES - [role]).each do |other|
          expect(user.public_send("#{other.parameterize(separator: "_")}?")).to be(false)
        end
      end
    end
  end

  describe "#active?" do
    it "is true only for Active users" do
      expect(build(:user, status: "Active")).to be_active
      expect(build(:user, status: "Deactivated")).not_to be_active
    end
  end

  describe "#selectable_statuses" do
    it "includes Archived for admins" do
      admin = build(:user, role: "Admin")
      expect(admin.selectable_statuses(Box)).to eq(Box::STATUSES)
    end

    it "excludes Archived for everyone else" do
      ["Volunteer", "Shipping Manager", "Receiving Manager"].each do |role|
        statuses = build(:user, role: role).selectable_statuses(Pallet)
        expect(statuses).not_to include(Pallet::ARCHIVED)
        expect(statuses).to match_array(Pallet::STATUSES - [Pallet::ARCHIVED])
      end
    end
  end

  describe "#created_records?" do
    it "is false for a user with no records" do
      expect(subject.created_records?).to be(false)
    end

    it "is true once the user has created an item" do
      create :item, user: subject
      expect(subject.created_records?).to be(true)
    end

    it "is true once the user has created a box" do
      create :box, user: subject, pallet: nil, container: nil
      expect(subject.created_records?).to be(true)
    end
  end

  describe "authentication" do
    it "authenticates with the correct password only" do
      expect(subject.authenticate("1234567890")).to eq(subject)
      expect(subject.authenticate("wrong")).to be(false)
    end
  end
end
