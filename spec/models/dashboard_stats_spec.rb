# frozen_string_literal: true

require "rails_helper"

describe DashboardStats do
  subject(:stats) { described_class.new(user, range: "30") }

  let(:warehouse) { create :warehouse }
  let(:user) { create :user, status: "Active", role: "Volunteer", warehouse: warehouse }
  let(:other) { create :user, status: "Active", role: "Volunteer", first_name: "Ama" }

  def packed(by: user, at: Time.current, **attrs)
    create(:packed_item, user: by, box: nil, pallet: nil, container: nil, shipment: nil,
                         status: PackedItem::STAGED, **attrs).tap { |pi| pi.update_columns(created_at: at) }
  end

  it "offers 30 days, a year and all time, defaulting to a year" do
    expect(described_class.new(user).range).to eq("year")
    expect(described_class.new(user, range: "7").range).to eq("year")
    expect(described_class.new(user, range: "all").range).to eq("all")
  end

  describe "all time" do
    subject(:stats) { described_class.new(user, range: "all") }

    it "counts everything, with nothing to compare against" do
      packed(at: 2.days.ago)
      packed(at: 3.years.ago)

      tile = stats.tiles.find { |t| t.label == "Packed items" }
      expect([tile.value, tile.previous, tile.direction]).to eq([2, nil, :none])
      expect(tile).not_to be_comparable
      expect(stats.leaderboards.find { |b| b.key == :packed }.rows.first.value).to eq(2)
      expect(stats.period_name).to eq("all time")
      expect(stats.previous_period_name).to be_nil
    end
  end

  describe "#tiles" do
    it "compares this period with the one before, and knows which way is good" do
      3.times { packed(at: 2.days.ago) }
      packed(at: 40.days.ago)
      create(:item, verified: false).update_columns(created_at: 2.days.ago)

      tile = stats.tiles.find { |t| t.label == "Packed items" }
      expect([tile.value, tile.previous, tile.change, tile.direction]).to eq([3, 1, 200, :up])
      expect(tile).to be_good_news

      unverified = stats.tiles.find { |t| t.label == "New unverified items" }
      expect(unverified.direction).to eq(:up)
      expect(unverified).not_to be_good_news
    end

    it "has no percentage when the previous period was empty" do
      packed(at: 1.day.ago)
      tile = stats.tiles.find { |t| t.label == "Packed items" }

      expect(tile.change).to be_nil
      expect(tile.direction).to eq(:up)
    end
  end

  describe "#weekly_packed" do
    it "has a bar for every one of the last 12 weeks, zeros included" do
      packed(at: Time.current)
      packed(at: 3.weeks.ago)

      weeks = stats.weekly_packed
      expect(weeks.size).to eq(12)
      expect(weeks.values.last).to eq(1)
      expect(weeks.values.sum).to eq(2)
    end
  end

  describe "#leaderboards and #rank_on" do
    it "ranks people by count and finds the viewer" do
      2.times { packed(by: other) }
      packed(by: user)

      board = stats.leaderboards.find { |b| b.key == :packed }
      expect(board.rows.map(&:name)).to eq(["Ama", user.first_name])
      expect(stats.rank_on(board)).to eq(rank: 2, of: 2, value: 1)
    end
  end

  describe "#streak" do
    it "counts consecutive weeks, not breaking on a quiet current week" do
      packed(at: 1.week.ago)
      packed(at: 2.weeks.ago)
      packed(at: 4.weeks.ago)

      expect(stats.streak).to eq(2)
    end

    it "is zero with nothing recent" do
      packed(at: 10.weeks.ago)
      expect(stats.streak).to eq(0)
    end
  end

  describe "#milestones" do
    it "lists milestones reached and the next one" do
      12.times { packed }

      expect(stats.milestones).to eq(count: 12, reached: [10], next: 50)
    end
  end

  describe "receiving manager stats" do
    let(:user) { create :user, status: "Active", role: "Receiving Manager", warehouse: warehouse }
    let(:hospital) { create :hospital, warehouse: warehouse }
    let(:shipment) { create :shipment, receiving_warehouse: warehouse }
    let(:container) { create :container, shipment: shipment }

    before do
      in_stock = create :packed_item, container: container, box: nil, pallet: nil, shipment: shipment,
                                      quantity: 10, weight: 20, expiry_date: 30.days.from_now
      create :packed_item, container: container, box: nil, pallet: nil, shipment: shipment,
                           quantity: 5, expiry_date: 1.year.ago
      shipment.update!(status: Shipment::RECEIVED)
      create :unpacking_event, packed_item: in_stock.reload, hospital: hospital, quantity: 4
    end

    it "summarises stock, estimating weight from what is left" do
      tiles = stats.receiving.received_tiles

      expect(tiles.values_at(:lines, :remaining, :weight, :expired)).to eq([2, 11, 12, 1])
      expect(tiles[:earliest_expiry].to_date).to eq(30.days.from_now.to_date)
      expect(stats.receiving.expiring_soon_count).to eq(1)
    end
  end
end

describe DashboardStats::Unpacking do
  let(:warehouse) { create :warehouse }
  let(:other_warehouse) { create :warehouse }
  let(:user) { create :user, status: "Active", role: "Receiving Manager", warehouse: warehouse }
  let(:category) { create :category, name: "Dressings" }
  let(:gauze) { create :item, object: "Gauze", category: category }
  let(:near) { create :hospital, name: "Ridge", warehouse: warehouse }
  let(:far) { create :hospital, name: "Tema", warehouse: other_warehouse }
  let(:stock) do
    create :packed_item, item: gauze, box: nil, pallet: nil, container: nil, shipment: nil,
                         status: PackedItem::WAREHOUSED, quantity: 100
  end

  def unpack(hospital, quantity, at:)
    create :unpacking_event, packed_item: stock, hospital: hospital, quantity: quantity, timestamp: at
  end

  def stats_for(warehouse)
    DashboardStats.new(user, range: "30").unpacking(everywhere: warehouse.nil?)
  end

  before do
    unpack(near, 10, at: 2.days.ago)
    unpack(near, 6, at: 3.days.ago)
    unpack(far, 5, at: 4.days.ago)
    unpack(near, 8, at: 40.days.ago)
  end

  it "compares units, handovers and destinations with the previous period, for one warehouse" do
    summary = stats_for(warehouse).summary

    expect([summary[:units].value, summary[:units].previous]).to eq([16, 8])
    expect([summary[:handovers].value, summary[:handovers].previous]).to eq([2, 1])
    expect([summary[:served].value, summary[:served].previous]).to eq([1, 1])
    expect(summary[:per_handover]).to eq(8)
  end

  it "covers every warehouse for admins, with a per-warehouse breakdown" do
    unpacking = stats_for(nil)

    expect(unpacking.summary[:units].value).to eq(21)
    expect(unpacking.by_warehouse).to eq([[warehouse.name, 16], [other_warehouse.name, 5]])
  end

  it "breaks the period down by destination, item and category" do
    unpacking = stats_for(warehouse)

    expect(unpacking.by_destination).to eq([["Ridge", 16]])
    expect(unpacking.top_items).to eq([[gauze.generated_name, 16]])
    expect(unpacking.by_category).to eq([["Dressings", 16]])
    expect(unpacking.weekly_units.values.sum).to eq(24) # 12 weeks, so the 40-day-old one counts too
  end

  it "shows nothing, not every warehouse, to someone with no warehouse" do
    user.update!(warehouse: nil)
    unpacking = DashboardStats.new(user.reload, range: "30").unpacking

    expect(unpacking.summary[:units].value).to eq(0)
    expect(unpacking.by_destination).to eq([])
    expect(unpacking.quiet_destinations).to eq([])
  end

  it "spots first-ever deliveries and destinations left waiting" do
    waiting = create :hospital, name: "Bong Mines", warehouse: warehouse
    create :hospital, name: "Closed Clinic", warehouse: warehouse, status: Hospital::DEACTIVATED

    unpacking = stats_for(warehouse)
    expect(unpacking.first_time_destinations).to eq([])
    expect(unpacking.quiet_destinations).to eq([{ id: waiting.id, name: "Bong Mines", last: nil }])

    expect(stats_for(nil).first_time_destinations).to eq(["Tema"])
  end
end
