# frozen_string_literal: true

require "rails_helper"

describe "Dashboard", type: :request do
  let(:warehouse) { create :warehouse }

  def sign_in_as(role)
    user = create :user, status: "Active", role: role, warehouse: warehouse
    sign_in user
    user
  end

  before do
    packer = create :user, status: "Active", role: "Volunteer"
    create :packed_item, user: packer, box: nil, pallet: nil, container: nil, shipment: nil,
                         status: PackedItem::STAGED, quantity: 3, weight: 2
  end

  it "shows packers their activity, leaderboard and milestones" do
    sign_in_as "Volunteer"
    get index_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Packing Activity (Past year)", "Items packed per week", "Leaderboard",
                                     "Packing milestones", "Just For Fun")
    expect(response.body).not_to include("Shipment pipeline", "Inventory at", "Unpacking &amp; Destinations",
                                         "Recently Added Users")
  end

  it "gives shipping managers the pipeline, every warehouse's unpacking and the recent records" do
    sign_in_as "Shipping Manager"
    get index_path

    expect(response.body).to include("Shipment pipeline", "Item catalogue quality", "Unpacking &amp; Destinations",
                                     "By warehouse", "Recently Added Users", "Recently Added Items",
                                     "Recently Unpacked Items")
  end

  it "shows receiving managers their warehouse's inventory instead of packing stats" do
    sign_in_as "Receiving Manager"
    get index_path

    expect(response.body).to include("Inventory at #{warehouse.name}", "Stock by category", "Expiring in the next 90 days",
                                     "Unpacking at #{warehouse.name}", "Top destinations", "Units unpacked per week")
    expect(response.body).not_to include("By warehouse")
    expect(response.body).not_to include("Packing Activity", "Leaderboard")
  end

  it "keeps the recent records tables for admins" do
    sign_in_as "Admin"
    get index_path

    expect(response.body).to include("Recently Added Users", "Recently Added Items", "Recently Unpacked Items",
                                     "Unpacking &amp; Destinations", "By warehouse")
  end

  it "switches the time range, including all time" do
    sign_in_as "Admin"
    get index_path(range: "30")
    expect(response.body).to include("Packing Activity (Past 30 days)")

    get index_path(range: "all")
    expect(response.body).to include("Packing Activity (All time)", "Unpacking &amp; Destinations (All time)", "Items created")
    expect(response.body).not_to include("First delivery ever", "vs previous")
  end
end
