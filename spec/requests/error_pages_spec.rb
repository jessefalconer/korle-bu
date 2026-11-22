# frozen_string_literal: true

require "rails_helper"

# What people see when something goes wrong in production: the static pages in
# public/, rendered by Rails (404, 400, 422) or by nginx when the app is down (500).
describe "Error pages", type: :request do
  let(:admin) { create :user, status: "Active", role: "Admin" }

  # Behave like production for these examples: the public error pages instead of
  # debug output (the test environment's own setting would override a per-request one)
  around do |example|
    config = Rails.application.env_config
    keys = %w[action_dispatch.show_exceptions action_dispatch.show_detailed_exceptions]
    original = config.slice(*keys)
    config.merge!("action_dispatch.show_exceptions" => :all, "action_dispatch.show_detailed_exceptions" => false)
    example.run
  ensure
    keys.each { |key| original.key?(key) ? config[key] = original[key] : config.delete(key) }
  end

  before { sign_in admin }

  def page_heading
    response.parsed_body.at_css("h1").text
  end

  it "shows the not-found page for a missing record" do
    get box_path(0)

    expect(response).to have_http_status(:not_found)
    expect(page_heading).to eq("We can't find that page")
  end

  it "shows the bad-request page when required form data is missing" do
    post boxes_path, params: { not_a_box: {} }

    expect(response).to have_http_status(:bad_request)
    expect(page_heading).to eq("We couldn't understand that request")
  end

  %w[400 404 422 500].each do |code|
    it "keeps #{code}.html self-contained, with a way back and a way to report it" do
      html = Rails.public_path.join("#{code}.html").read
      page = Nokogiri::HTML(html)

      expect(page.at_css(".code").text).to eq("Error #{code}")
      expect(page.css("link[rel=stylesheet], script")).to be_empty # works with the app down
      expect(page.css(".actions a").pluck("href")).to eq(["javascript:history.back()", "/"])
      expect(page.at_css(".help a")["href"]).to start_with("mailto:jesse@kbnf.org")
    end
  end

  it "explains an expired form on the 422 page (Rails' answer to a stale form)" do
    expect(Rails.public_path.join("422.html").read).to include("This page has expired", "refresh the page")
  end
end
