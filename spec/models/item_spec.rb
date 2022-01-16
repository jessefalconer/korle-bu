# frozen_string_literal: true

require "rails_helper"

describe Item do
  subject { create :item, user: user }

  let(:user) { create :user }

  describe "item naming" do
    it "removes unwanted whitespace" do
      subject.update(generated_name: " Topical   solution")
      expect(subject.generated_name).to eq("Topical solution")
    end
  end
end
