# frozen_string_literal: true

require "rails_helper"

# The received-inventory pages for a receiving warehouse: correct contents, SQL-side
# pagination and totals, and no N+1 queries as inventory grows.
describe "Received items", type: :request do
  let(:warehouse) { create :warehouse }
  let(:user) { create :user, status: "Active", role: "Admin", warehouse: warehouse }
  let(:shipment) { create(:shipment, receiving_warehouse: warehouse).tap { |s| s.update!(status: Shipment::RECEIVED) } }
  let(:container) { create :container, shipment: shipment }
  let(:category) { create :category }

  before do
    skip_webpacker_assets
    create :hospital, warehouse: warehouse
    sign_in user
  end

  def packed_item(item: create(:item, category: category), quantity: 3, **parents)
    create :packed_item, { box: nil, pallet: nil, container: nil, shipment: nil, item: item, quantity: quantity }.merge(parents)
  end

  # One packed item of `item` in each kind of location in the received shipment.
  def stock_everywhere(item)
    pallet = create :pallet, container: container
    packed_item(item: item, container: container)
    packed_item(item: item, pallet: pallet)
    packed_item(item: item, box: create(:box, pallet: pallet, container: nil))
    packed_item(item: item, box: create(:box, container: container, pallet: nil))
  end

  def expect_constant_queries(path, add_rows)
    add_rows.call
    baseline = queries_for_get(path)

    3.times { add_rows.call }
    expect(queries_for_get(path)).to eq(baseline)
  end

  describe "GET /all_received_items" do
    it "lists categorized items with stock, sorted by name and paginated in SQL" do
      allow(Kaminari.config).to receive(:default_per_page).and_return(2)
      %w[Cotton Bandage Aspirin].each { |name| packed_item(item: create(:item, object: name, category: category), container: container) }
      packed_item(item: create(:item, object: "Uncategorized Thing"), container: container)
      packed_item(item: create(:item, object: "Elsewhere", category: category), container: create(:container))

      get "/all_received_items"
      expect(response.body).to include("Aspirin", "Bandage")
      expect(response.body).not_to include("Cotton", "Uncategorized Thing", "Elsewhere")

      get "/all_received_items?page=2"
      expect(response.body).to include("Cotton")
      expect(response.body).not_to include("Aspirin")
    end

    it "groups every location of an item under it" do
      item = create :item, object: "Gauze", category: category
      stock_everywhere(item)

      get "/all_received_items"
      expect(response.body.scan("quantity-").size).to eq(4)
    end

    it "does not N+1 as inventory grows" do
      expect_constant_queries("/all_received_items", -> { stock_everywhere(create(:item, category: category)) })
    end
  end

  describe "GET /received_categories" do
    it "totals distinct items and remaining stock per category, plus uncategorized" do
      other = create :category, name: "Another"
      gauze = create :item, category: category
      packed_item(item: gauze, quantity: 2, container: container)
      packed_item(item: gauze, quantity: 5, pallet: create(:pallet, container: container))
      packed_item(item: create(:item, category: other), quantity: 4, container: container)
      packed_item(item: create(:item), quantity: 7, container: container)
      packed_item(item: create(:item), quantity: 1, container: container)

      get "/received_categories"

      rows = Nokogiri::HTML(response.body).css("tbody tr").map { |tr| tr.css("td p").map { |p| p.text.strip } }
      expect(rows).to eq([
        ["Another", "", "1", "4"],
        [category.name, "", "1", "7"],
        ["Uncategorized", "N/A", "2", "8"]
      ])
    end

    it "does not N+1 as categories grow" do
      expect_constant_queries("/received_categories", lambda {
        packed_item(item: create(:item, category: create(:category)), container: container)
        packed_item(item: create(:item), container: container)
      })
    end
  end

  describe "GET /received_category_items/:id/received_item_locations" do
    it "does not N+1 as locations grow" do
      item = create :item, category: category
      expect_constant_queries("/received_category_items/#{item.id}/received_item_locations", -> { stock_everywhere(item) })
    end
  end

  describe "GET /received_categories/:id/received_category_items" do
    it "does not N+1 as items grow" do
      expect_constant_queries("/received_categories/#{category.id}/received_category_items", -> { stock_everywhere(create(:item, category: category)) })
    end
  end

  describe "GET /packed_item_search" do
    it "does not N+1 as matching inventory grows" do
      expect_constant_queries("/packed_item_search?search=Gauze", lambda {
        stock_everywhere(create(:item, object: "Gauze #{SecureRandom.hex(3)}", category: category))
      })
    end
  end
end
