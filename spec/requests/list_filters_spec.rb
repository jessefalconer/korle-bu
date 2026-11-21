# frozen_string_literal: true

require "rails_helper"

# The filter bar above the item, shipment, container, pallet and box lists.
describe "List filters", type: :request do
  let(:admin) { create :user, status: "Active", role: "Admin", first_name: "Ada" }
  let(:packer) { create :user, status: "Active", role: "Volunteer", first_name: "Kofi" }
  let(:ghana) { create :warehouse, name: "Accra" }
  let(:liberia) { create :warehouse, name: "Monrovia" }

  before { sign_in admin }

  def names
    response.parsed_body.css("tbody tr td:nth-child(2)").map { |td| td.text.strip }
  end

  def created(record, days_ago)
    record.tap { |r| r.update_columns(created_at: days_ago.days.ago) }
  end

  describe "shipments" do
    let!(:to_ghana) { create :shipment, name: "To Ghana", receiving_warehouse: ghana, status: Shipment::RECEIVED }
    let!(:to_liberia) { create :shipment, name: "To Liberia", receiving_warehouse: liberia, user: packer }

    it "filters by several statuses at once" do
      get shipments_path(f: { status: [Shipment::RECEIVED, Shipment::COMPLETE] })
      expect(names).to eq(["To Ghana"])

      get shipments_path(f: { status: [Shipment::RECEIVED, Shipment::IN_PROGRESS] })
      expect(names).to contain_exactly("To Ghana", "To Liberia")
    end

    it "filters by receiver and by who created them" do
      get shipments_path(f: { receiver: liberia.id })
      expect(names).to eq(["To Liberia"])

      get shipments_path(f: { user: [packer.id] })
      expect(names).to eq(["To Liberia"])
    end

    it "filters by creation date range, inclusive" do
      created(to_ghana, 10)
      created(to_liberia, 2)

      get shipments_path(f: { from: 3.days.ago.to_date.iso8601, to: Date.current.iso8601 })
      expect(names).to eq(["To Liberia"])

      get shipments_path(f: { to: 10.days.ago.to_date.iso8601 })
      expect(names).to eq(["To Ghana"])
    end

    it "ignores values it doesn't recognise" do
      get shipments_path(f: { status: ["Lost at sea"], from: "yesterday", receiver: "1 OR 1=1", user: ["x"] })

      expect(response).to have_http_status(:ok)
      expect(names).to contain_exactly("To Ghana", "To Liberia")
    end
  end

  describe "boxes, pallets and containers" do
    let(:shipment) { create :shipment, receiving_warehouse: ghana }
    let(:container) { create :container, name: "C-Ghana", shipment: shipment }

    it "finds boxes by receiver through their container or their pallet" do
      create :box, name: "In container", container: container, pallet: nil
      create :box, name: "On pallet", pallet: create(:pallet, container: container), container: nil
      create :box, name: "Loose", pallet: nil, container: nil

      get boxes_path(f: { receiver: ghana.id })
      expect(names).to contain_exactly("In container", "On pallet")

      get boxes_path(f: { receiver: "none" })
      expect(names).to eq(["Loose"])
    end

    it "leaves Staged and Warehoused out of the main box and pallet lists and their filters" do
      create :box, name: "Packing", pallet: nil, container: nil, status: Box::IN_PROGRESS
      create :box, name: "On the shelf", pallet: nil, container: nil, status: Box::WAREHOUSED

      get boxes_path(f: { status: [Box::WAREHOUSED, Box::IN_PROGRESS] })
      expect(names).to eq(["Packing"])

      %w[boxes pallets].each do |list|
        get "/#{list}"
        offered = response.parsed_body.css("input[name='f[status][]']").map { |box| box["value"] }
        expect(offered).to eq(["In Progress", "Complete", "Received", "Archived"])
      end
    end

    it "filters pallets and containers by receiver" do
      create :pallet, name: "P-Ghana", container: container
      create :pallet, name: "P-Nowhere", container: nil
      create :container, name: "C-Nowhere", shipment: nil

      get pallets_path(f: { receiver: ghana.id })
      expect(names).to eq(["P-Ghana"])

      get containers_path(f: { receiver: "none" })
      expect(names).to eq(["C-Nowhere"])
    end

    it "keeps the page's own view (display) and offers no status filter there" do
      create :box, name: "Staged one", pallet: nil, container: nil, status: Box::STAGED, user: packer
      create :box, name: "Staged other", pallet: nil, container: nil, status: Box::STAGED

      get boxes_path(display: "staged", f: { user: [packer.id] })
      expect(names).to eq(["Staged one"])
      expect(response.parsed_body.at_css("input[name='f[status][]']")).to be_nil
      expect(response.parsed_body.at_css(".list-filter input[name='display']")["value"]).to eq("staged")
    end
  end

  describe "items" do
    let(:category) { create :category, name: "Dressings" }
    let!(:gauze) { create :item, object: "Gauze", category: category, user: packer }
    let!(:tape) { create :item, object: "Tape" }

    def item_names
      response.parsed_body.css("tbody tr td:first-child").map { |td| td.text.strip }
    end

    before { create :packed_item, item: gauze, box: nil, pallet: nil, container: nil, shipment: nil, status: PackedItem::STAGED }

    it "filters by category, including uncategorized" do
      get items_path(f: { category: category.id })
      expect(item_names).to eq([gauze.generated_name])

      get items_path(f: { category: "none" })
      expect(item_names).to eq([tape.generated_name])
    end

    it "filters by whether the item is used anywhere" do
      get items_path(f: { instances: "used" })
      expect(item_names).to eq([gauze.generated_name])

      get items_path(f: { instances: "unused" })
      expect(item_names).to eq([tape.generated_name])
    end

    it "filters by creator and creation date" do
      created(tape, 30)

      get items_path(f: { user: [packer.id] })
      expect(item_names).to eq([gauze.generated_name])

      get items_path(f: { from: 7.days.ago.to_date.iso8601 })
      expect(item_names).to eq([gauze.generated_name])
    end

    describe "searching together with filters" do
      let!(:gauze_pad) { create :item, object: "Gauze Pad" }

      it "narrows a search by the filters, and counts and pages what's left" do
        get items_path(search_string: "gauze", f: { instances: "unused" })

        expect(item_names).to eq([gauze_pad.generated_name])
        expect(response.parsed_body.at_css(".list-filter-total").text.strip).to eq("1 result")
      end

      it "puts the search box in the filter form, so Apply keeps the search" do
        get items_path(search_string: "gauze")
        box = response.parsed_body.at_css("#item-search")

        expect(box["form"]).to eq("list-filter-form")
        expect(box["value"]).to eq("gauze")
        expect(response.parsed_body.at_css("#list-filter-form input[name='search_string']")).to be_nil
      end

      it "keeps the search when filters are cleared" do
        get items_path(search_string: "gauze", f: { instances: "unused" })

        expect(response.parsed_body.at_css(".list-filter a.btn-cancel")["href"]).to eq(items_path(search_string: "gauze"))
      end

      it "treats a blank search box as no search" do
        get items_path(search_string: "", f: { category: "none" })

        expect(item_names).to contain_exactly(tape.generated_name, gauze_pad.generated_name)
      end

      it "says what matched nothing" do
        get items_path(search_string: "zebra", f: { instances: "used" })

        expect(response.parsed_body.at_css(".empty-state").text).to eq("No items match \"zebra\" with these filters.")
      end
    end

    it "applies the filters to the live search too" do
      get index_item_search_path(search: "Gauze", f: { instances: "unused" })

      expect(response.body).not_to include("Gauze")
    end
  end

  describe "the filter bar" do
    it "opens and counts the filters set, and offers a way to clear them" do
      get shipments_path(f: { status: [Shipment::RECEIVED], from: "2026-01-01", to: "2026-02-01" })
      bar = response.parsed_body.at_css("details.list-filter")

      expect(bar.key?("open")).to be(true)
      expect(bar.at_css("summary .badge").text).to eq("2")
      expect(bar.at_css("a.btn-cancel")["href"]).to eq(shipments_path)
    end

    it "stays closed when nothing is set" do
      get containers_path

      expect(response.parsed_body.at_css("details.list-filter").key?("open")).to be(false)
    end
  end
end
