# frozen_string_literal: true

require "rails_helper"

describe Item do
  subject { create :item, user: user }

  let(:user) { create :user }

  describe "item naming" do
    it "generates a formatted name based on multiple components" do
      subject.update(object: "Syringe", numerical_units_1: "mL", numerical_description_1: "Tube", numerical_size_1: 15.000)
      expect(subject.generated_name).to eq("Syringe 15mL Tube")
    end

    it "removes unwanted whitespace" do
      subject.update(object: " Topical   solution")
      expect(subject.generated_name).to eq("Topical solution")
    end
  end
end
