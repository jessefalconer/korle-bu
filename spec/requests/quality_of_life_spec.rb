# frozen_string_literal: true

require "rails_helper"

# Small helpers that save repeated clicks: recent items, weight from unit
# weight, remembered unpack choices and a sticky dashboard range.
describe "Quality of life helpers", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:warehouse) { create :warehouse }
  let(:volunteer) { create :user, status: "Active", role: "Volunteer", warehouse: warehouse }
  let(:open_box) { create :box, pallet: nil, container: nil, status: Box::IN_PROGRESS }

  def page
    response.parsed_body
  end

  describe "recently used items" do
    it "lists the viewer's last packed items, newest first, each once" do
      gauze = create :item, object: "Gauze", unit_weight: 0.25
      tape = create :item, object: "Tape"
      create(:packed_item, item: gauze, user: volunteer, box: open_box, pallet: nil, container: nil).update_columns(created_at: 2.days.ago)
      create(:packed_item, item: tape, user: volunteer, box: open_box, pallet: nil, container: nil).update_columns(created_at: 1.day.ago)
      create(:packed_item, item: gauze, user: volunteer, box: open_box, pallet: nil, container: nil).update_columns(created_at: 3.days.ago)
      create :packed_item, item: create(:item, object: "Someone Else's"), box: open_box, pallet: nil, container: nil

      expect(Item.recently_packed_by(volunteer)).to eq([[tape.id, tape.generated_name, 0.0],
                                                        [gauze.id, gauze.generated_name, 0.25]])

      sign_in volunteer
      get box_box_items_path(open_box)
      names = page.css("#recent-items .results-item-name-value").map(&:text)
      expect(names).to eq([tape.generated_name, gauze.generated_name])
      expect(page.at_css("#recent-items form")["action"]).to eq(box_box_items_path(open_box))
    end

    it "shows nothing for someone who hasn't packed anything" do
      sign_in volunteer
      get staged_items_path

      expect(page.at_css("#recent-items")).to be_nil
    end
  end

  describe "weight from unit weight" do
    it "pre-fills one unit's weight and tells the page the unit weight" do
      gauze = create :item, object: "Gauze", unit_weight: 0.25
      create :packed_item, item: gauze, user: volunteer, box: open_box, pallet: nil, container: nil

      sign_in volunteer
      get box_box_items_path(open_box)
      form = page.at_css("#recent-items form")

      expect(form["data-unit-weight"]).to eq("0.25")
      expect(form.at_css(".js-weight")["value"]).to eq("0.25")
    end

    it "leaves weight blank when the item has no unit weight" do
      create :packed_item, item: create(:item, object: "Tape"), user: volunteer, box: open_box, pallet: nil, container: nil

      sign_in volunteer
      get box_box_items_path(open_box)
      form = page.at_css("#recent-items form")

      expect(form["data-unit-weight"]).to be_nil
      expect(form.at_css(".js-weight")["value"]).to be_nil
    end
  end

  describe "the search box" do
    it "is focused on arrival and explains the keyboard flow" do
      sign_in volunteer
      get box_box_items_path(open_box)

      expect(page.at_css("#search-params")["autofocus"]).to eq("autofocus")
      expect(page.at_css("#search-keys-hint").text).to include("Enter again to open the first result")
    end
  end

  describe "remembered unpack choices" do
    let(:manager) { create :user, status: "Active", role: "Receiving Manager", warehouse: warehouse }
    let(:hospital) { create :hospital, warehouse: warehouse }
    let(:shipment) { create :shipment, receiving_warehouse: warehouse }
    let(:container) { create :container, shipment: shipment }
    let!(:first_item) { create :packed_item, container: container, box: nil, pallet: nil, shipment: shipment, quantity: 3 }
    let!(:second_item) { create :packed_item, container: container, box: nil, pallet: nil, shipment: shipment, quantity: 3 }

    before do
      create :hospital, name: "Aaa First Alphabetically", warehouse: warehouse
      shipment.update!(status: Shipment::RECEIVED)
      sign_in manager
    end

    def unpack(item, date)
      post received_categories_unpack_selected_path, params: { item_ids: [item.id], hospital_id: hospital.id, timestamp: date }
    end

    def form_defaults
      get container_container_items_path(container)
      select = page.css("select[name='unpacking_event[hospital_id]']").first
      [select.at_css("option[selected]")&.text, page.css("input[name='unpacking_event[timestamp]']").first["value"]]
    end

    it "starts the next unpack form on the same hospital and date" do
      unpack(first_item, "2026-03-04")

      expect(form_defaults).to eq([hospital.name, "2026-03-04"])
    end

    it "keeps the hospital but goes back to today on another day" do
      unpack(first_item, "2026-03-04")
      travel 1.day do
        today = DateTime.current.in_time_zone(ApplicationHelper::UNPACK_TIME_ZONE).strftime("%Y-%m-%d")
        expect(form_defaults).to eq([hospital.name, today])
      end
    end

    it "remembers nothing when nothing was unpacked" do
      post received_categories_unpack_selected_path, params: { item_ids: [first_item.id], hospital_id: "" }

      expect(form_defaults.first).to be_nil
    end
  end

  describe "the dashboard range" do
    it "sticks for the rest of the session" do
      sign_in volunteer
      get index_path(range: "30")
      get index_path
      expect(response.body).to include("Packing Activity (Past 30 days)")

      get index_path(range: "all")
      get index_path
      expect(response.body).to include("Packing Activity (All time)")
    end
  end
end
