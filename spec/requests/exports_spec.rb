# frozen_string_literal: true

require "rails_helper"

describe "CSV exports", type: :request do
  let(:admin) { create :user, status: "Active", role: "Admin" }

  before { sign_in admin }

  describe "POST /shipment_exports" do
    let(:shipment) { create :shipment }
    let(:container) { create :container, shipment: shipment }

    before do
      item = create :item, object: "Gauze"
      create :packed_item, item: item, container: container, box: nil, pallet: nil, quantity: 3
    end

    it "sends a CSV attachment named after the shipment" do
      post shipment_exports_path, params: { shipment_export: { id: shipment.id, group_by: "item" } }

      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Disposition"]).to include("Shipment--#{shipment.id}-#{Time.zone.today}.csv")
      expect(CSV.parse(response.body).last).to eq(["Gauze", "3", "N/A", "0", container.name])
    end

    it "marks the file as UTF-8 so Excel shows accented names correctly" do
      post shipment_exports_path, params: { shipment_export: { id: shipment.id, group_by: "item" } }

      expect(response.media_type).to eq("text/csv")
      expect(response.headers["Content-Type"]).to include("charset=utf-8")
      expect(response.body).to start_with("\uFEFFItem,")
    end
  end

  describe "POST /hospital_exports" do
    let(:hospital) { create :hospital, name: "Ridge" }

    it "sends a CSV attachment named after the hospital" do
      post hospital_exports_path, params: { hospital_export: { id: hospital.id } }

      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Disposition"]).to include("Hospital--Ridge--#{Time.zone.today}.csv")
      expect(CSV.parse(response.body.delete_prefix(CsvSafety::BOM))).to eq([%w[Item Category Quantity User Date]])
    end
  end

  describe "spreadsheet safety in the hospital and unpacking exports" do
    let(:hospital) { create :hospital, name: "Ridge" }

    before do
      item = create :item, object: "=cmd|' /C calc'!A0"
      packed = create :packed_item, item: item, box: nil, pallet: nil, container: nil, status: PackedItem::WAREHOUSED, quantity: 5
      create :unpacking_event, packed_item: packed, hospital: hospital, quantity: 2
    end

    def cells
      CSV.parse(response.body.delete_prefix(CsvSafety::BOM)).flatten.compact
    end

    it "neutralises formula cells and marks the hospital export as UTF-8" do
      post hospital_exports_path, params: { hospital_export: { id: hospital.id } }

      expect(response.body).to start_with("\uFEFF")
      expect(response.headers["Content-Type"]).to include("charset=utf-8")
      expect(cells).to include(start_with("'=cmd"))
      expect(cells).not_to include(start_with("=cmd"))
    end

    it "neutralises formula cells and marks the unpacking events export as UTF-8" do
      post unpacking_events_exports_path, params: { unpacking_events_export: { hospital_id: hospital.id } }

      expect(response.body).to start_with("\uFEFF")
      expect(cells).to include(start_with("'=cmd"))
      expect(cells).not_to include(start_with("=cmd"))
    end
  end
end
