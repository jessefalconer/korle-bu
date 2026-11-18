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
  end

  describe "POST /hospital_exports" do
    let(:hospital) { create :hospital, name: "Ridge" }

    it "sends a CSV attachment named after the hospital" do
      post hospital_exports_path, params: { hospital_export: { id: hospital.id } }

      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Disposition"]).to include("Hospital--Ridge--#{Time.zone.today}.csv")
      expect(CSV.parse(response.body)).to eq([%w[Item Category Quantity User Date]])
    end
  end
end
