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
    expect(help_path).to eq("/help")
    expect(dev_updates_path).to eq("/dev_updates")
  end

  it "sends the retired help pages to the matching section of /help" do
    get "/admin_help"
    expect(response).to redirect_to("/help#shipping")

    get "/volunteer_help"
    expect(response).to redirect_to("/help#volunteers")
  end

  # Help, Privacy and Developer Updates share one layout: a contents list whose
  # links all lead to a section on the same page
  {
    "/help" => %w[basics volunteers shipping receiving admins],
    "/privacy" => %w[what-we-keep who-can-see-it cookies questions],
    "/dev_updates" => %w[update-21-nov-2026 update-19-nov-2026 update-29-jan-2021]
  }.each do |path, sections|
    it "gives #{path} a contents list whose links all lead somewhere on the page" do
      get path
      page = response.parsed_body
      targets = page.css("nav.toc a").map { |a| a["href"].delete_prefix("#") }

      expect(targets).to include(*sections)
      expect(targets - page.css("section.part[id], h3[id]").pluck("id")).to be_empty
      expect(page.css("img").pluck("src")).to eq(["/kbnf-logo.png"])
    end
  end

  it "lists the improved help documents as the latest developer update" do
    get "/dev_updates"
    latest = response.parsed_body.at_css("section.part")

    expect(latest.at_css("h2").text).to include("21 Nov 2026", "Latest")
    expect(latest.text).to include("Improved help documents.")
  end

  {
    "Volunteer" => "volunteers", "Shipping Manager" => "shipping", "Receiving Manager" => "receiving", "Admin" => "admins"
  }.each do |role, section|
    it "opens Help at the #{section} section for a #{role}" do
      sign_in create(:user, status: "Active", role: role, warehouse: create(:warehouse))
      get index_path

      expect(response.parsed_body.css("a[href='/help##{section}']")).to be_present
      expect(response.body).not_to include("Coming Soon")
    end
  end

  it "pins Help, updates, privacy and the app's software versions to the foot of the sidebar" do
    sign_in create(:user, status: "Active", role: "Volunteer")
    get index_path
    footer = response.parsed_body.at_css(".sidebar-nav > ul.sidebar-footer")

    expect(footer.css("a").pluck("href")).to include("/help#volunteers", "/dev_updates", "/privacy")
    expect(footer.at_css(".sidebar-stack").text.squish)
      .to include("Ruby #{RUBY_VERSION}", "Rails #{Rails.version}", "PostgreSQL #{ApplicationHelper.postgres_version}")
    expect(ApplicationHelper.postgres_version).to match(/\A\d+(\.\d+)*\z/)
    expect(response.body).not_to include("Version #", "about-menu")
  end

  it "sends the retired /terms page to /privacy" do
    get "/terms"

    expect(response).to redirect_to("/privacy")
  end

  it "has a privacy page that says what is kept, who sees it, and who to ask" do
    get "/privacy"

    expect(response.body).to include("What we keep", "Who can see it", "72 hours", "mailto:jesse@kbnf.org")
    expect(response.body).not_to include("photos", "jailbreak")
  end

  it "answers the health check" do
    get "/up"

    expect(response).to have_http_status(:ok)
  end
end
