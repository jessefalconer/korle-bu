# frozen_string_literal: true

require "rails_helper"

describe Container do
  subject { create :container, user: user }

  let(:user) { create :user }

  describe "initializes with a default name and custom UID" do
    it "with a name" do
      container = Container.new
      expect(container.name).to eq("CONTAINER-1")
      expect(container.custom_uid).to eq(1)
      expect(container.status).to eq("In Progress")
    end
  end
end
