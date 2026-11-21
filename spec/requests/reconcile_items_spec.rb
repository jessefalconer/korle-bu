# frozen_string_literal: true

require "rails_helper"

describe "Reconcile items", type: :request do
  let(:admin) { create :user, status: "Active", role: "Admin" }

  before do
    sign_in admin
  end

  describe "progress meters on the reconcile lists" do
    before do
      create :item, object: "Gauze", verified: true
      create :item, object: "Tape", verified: false, flagged: true
      create :item, object: "Pins", verified: false
    end

    it "shows how many are verified and how many are left" do
      get reconcile_unverified_path

      expect(response.body).to include("1 of 3 items", "33%", "items left to go.")
      expect(response.body).to include('aria-valuenow="33"')
    end

    it "shows resolved flags" do
      get reconcile_flagged_path

      expect(response.body).to include("Resolved", "2 of 3 items", "66%")
    end

    it "celebrates when nothing is left" do
      get reconcile_uncategorized_path

      expect(response.body).to include("Categorized", "0 of 3 items", "3</strong>")
      Item.find_each { |item| item.update!(category: create(:category)) }

      get reconcile_uncategorized_path
      expect(response.body).to include("100%", "All done. Nothing left to reconcile here.")
    end
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
