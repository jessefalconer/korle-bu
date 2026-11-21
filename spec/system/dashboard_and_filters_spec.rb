# frozen_string_literal: true

require "rails_helper"

# Small page behaviours: remembered dashboard cards (src/dashboard_prefs.js) and
# the list filter's "Created by" dropdown (src/list_filter.js).
describe "Dashboard and list filter behaviour", type: :system do
  let(:admin) { create :user, status: "Active", role: "Admin" }

  before { log_in_as admin }

  it "remembers a collapsed dashboard card after reloading" do
    visit_page index_path
    expect(page).to have_css("#leaderboard-stats.show")

    find("a.card-header[href='#leaderboard-stats']").click
    # Saved when the collapse animation finishes (Bootstrap's "hidden" event)
    expect(page).to have_css("#leaderboard-stats.collapse:not(.show):not(.collapsing)", visible: :all)
    expect(page.evaluate_script("localStorage.getItem('dashboard:collapsed')")).to include("leaderboard-stats")

    visit_page index_path
    expect(page).to have_css("#leaderboard-stats.collapse:not(.show)", visible: :all)
    expect(find("a.card-header[href='#leaderboard-stats']")[:class]).to include("collapsed")
    expect(page).to have_css("#page-stats.show")
  end

  it "closes the Created by dropdown on a click elsewhere or Escape" do
    create :shipment, user: admin
    visit_page shipments_path
    find(".list-filter summary").click

    dropdown = find(".filter-dropdown")
    dropdown.find("summary").click
    expect(dropdown).to match_selector("[open]")
    find(".list-filter legend", text: "Status").click
    expect(dropdown).not_to match_selector("[open]")

    dropdown.find("summary").click
    dropdown.find("input[type=checkbox]").send_keys(:escape)
    expect(dropdown).not_to match_selector("[open]")
    expect(dropdown.find("summary")).to match_selector(":focus")
  end
end
