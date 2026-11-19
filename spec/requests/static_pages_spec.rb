# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Static pages", type: :request do
  StaticPagesController::PAGES.each do |page|
    it "serves /#{page} to guests without logging in" do
      get "/#{page}"

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/html")
      expect(response.body).to include("<html")
    end
  end

  it "keeps the named route helpers the layouts use" do
    expect(privacy_path).to eq("/privacy")
    expect(terms_path).to eq("/terms")
    expect(admin_help_path).to eq("/admin_help")
    expect(volunteer_help_path).to eq("/volunteer_help")
    expect(dev_updates_path).to eq("/dev_updates")
  end

  it "answers the health check" do
    get "/up"

    expect(response).to have_http_status(:ok)
  end
end
