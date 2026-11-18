# frozen_string_literal: true

require "rails_helper"

describe "Reconcile items", type: :request do
  let(:admin) { create :user, status: "Active", role: "Admin" }

  before do
    skip_webpacker_assets
    sign_in admin
  end

  describe "GET /reconcile/:id" do
    it "renders for a plain item with a similar item" do
      item = create :item, object: "Gauze"
      create :item, object: "Gauze Pad"

      get reconcile_start_path(item)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("<strong>Gauze</strong> Pad")
    end

    ["Pen (black ink)", "Gauze (4x4", "Gauze +ve", "Gauze *sterile*", "Gauze [10", "Gauze 4x4\\"].each do |name|
      it "renders when the item name is #{name.inspect}" do
        item = create :item, object: name
        create :item, object: "Gauze Pad"

        get reconcile_start_path(item)

        expect(response).to have_http_status(:ok)
      end
    end
  end
end
