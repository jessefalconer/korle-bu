# frozen_string_literal: true

require "rails_helper"

describe Item do
  subject { create :item, user: user }

  let(:user) { create :user }

  describe "item naming" do
    it "has one" do
      expect(subject.generated_name).to eq(subject.generated_name)
    end
  end
end
