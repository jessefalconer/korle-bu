# frozen_string_literal: true

require "rails_helper"

# Regression tests for request parameters that must never be trusted.
describe "Request parameter safety", type: :request do
  let!(:warehouse) { create :warehouse, user: create(:user, status: "Active", role: "Admin") }

  describe "POST /create_public_user (public sign-up)" do
    let(:params) do
      {
        user: {
          email: "newcomer@kbnf.org", first_name: "New", last_name: "Comer", phone: "604-555-0100",
          password: "secret123", password_confirmation: "secret123",
          role: "Admin", status: "Active", warehouse_id: warehouse.id
        }
      }
    end

    it "always creates a deactivated Volunteer, ignoring role, status and warehouse" do
      expect { post create_public_user_path, params: params }.to change(User, :count).by(1)

      user = User.find_by!(email: "newcomer@kbnf.org")
      expect(user.role).to eq("Volunteer")
      expect(user.status).to eq("Deactivated")
      expect(user.warehouse_id).to be_nil
    end

    it "does not let the new account sign in until approved" do
      post create_public_user_path, params: params
      sign_in User.find_by!(email: "newcomer@kbnf.org"), password: "secret123"

      expect(session[:user_id]).to be_nil
    end
  end

  describe "PATCH /users/:id" do
    let(:volunteer) { create :user, status: "Active", role: "Volunteer" }

    it "does not let a volunteer promote themselves or change their status" do
      sign_in volunteer
      patch user_path(volunteer), params: { user: { first_name: "Renamed", role: "Admin", status: "Deactivated" } }

      volunteer.reload
      expect(volunteer.first_name).to eq("Renamed")
      expect(volunteer.role).to eq("Volunteer")
      expect(volunteer.status).to eq("Active")
    end

    it "does not let a volunteer change their password through the profile form" do
      sign_in volunteer
      patch user_path(volunteer), params: { user: { password: "changed123", password_confirmation: "changed123" } }

      expect(volunteer.reload.authenticate("changed123")).to be(false)
    end

    it "still lets an admin change another user's role and status" do
      sign_in create(:user, status: "Active", role: "Admin")
      patch user_path(volunteer), params: { user: { role: "Shipping Manager", status: "Deactivated" } }

      volunteer.reload
      expect(volunteer.role).to eq("Shipping Manager")
      expect(volunteer.status).to eq("Deactivated")
    end

    it "lets a masquerader switch their own role" do
      tester = create :user, status: "Active", role: "Volunteer", masquerader: true
      sign_in tester
      patch user_path(tester), params: { user: { role: "Receiving Manager" } }

      expect(tester.reload.role).to eq("Receiving Manager")
    end
  end

  describe "PATCH /users/:id/change_password" do
    it "changes only the password, even for someone allowed to change roles" do
      user = create :user, status: "Active", role: "Volunteer"
      sign_in create(:user, status: "Active", role: "Admin")
      patch change_password_user_path(user),
        params: { user: { password: "changed123", password_confirmation: "changed123", role: "Admin" } }

      user.reload
      expect(user.authenticate("changed123")).to be_truthy
      expect(user.role).to eq("Volunteer")
    end
  end

  describe "index ?display= filters" do
    let(:admin) { create :user, status: "Active", role: "Admin" }

    before { sign_in admin }

    %w[boxes pallets containers].each do |resource|
      it "ignores method names that are not allowed filters on /#{resource}" do
        model = resource.classify.constantize
        create resource.singularize.to_sym, user: admin

        expect { get "/#{resource}", params: { display: "delete_all" } }.not_to change(model, :count)
        expect(response).to have_http_status(:ok)
      end

      it "still applies an allowed filter on /#{resource}" do
        get "/#{resource}", params: { display: "in_progress" }

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "item update redirects" do
    let(:admin) { create :user, status: "Active", role: "Admin" }
    let(:item) { create :item, user: admin }

    before { sign_in admin }

    it "returns to an allowed reconcile list" do
      patch item_path(item), params: { redirect: "reconcile_flagged_path", item: { brand: "Acme" } }

      expect(response).to redirect_to(reconcile_flagged_path)
    end

    it "ignores any other redirect value" do
      patch item_path(item), params: { redirect: "User.delete_all", item: { brand: "Acme" } }

      expect(response).to redirect_to(item_path(item))
      expect(User.count).to be_positive
    end
  end

  describe "Active Storage routes" do
    it "does not expose the direct-upload endpoint" do
      expect do
        post "/rails/active_storage/direct_uploads",
          params: { blob: { filename: "x.png", byte_size: 1, checksum: "x", content_type: "image/png" } }
      end.not_to change(ActiveStorage::Blob, :count)

      expect(response).to have_http_status(:not_found)
    end

    it "does not serve stored files" do
      get "/rails/active_storage/blobs/redirect/abc/x.png"

      expect(response).to have_http_status(:not_found)
    end
  end
end
