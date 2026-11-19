# frozen_string_literal: true

require "rails_helper"

describe "Sessions", type: :request do
  let(:user) { create :user, status: "Active" }

  describe "GET /login" do
    it "renders the login page for guests" do
      get login_path
      expect(response).to have_http_status(:ok)
    end

    it "redirects signed-in users to the dashboard" do
      sign_in user
      get login_path
      expect(response).to redirect_to(index_path)
    end
  end

  describe "POST /login" do
    it "signs in an active user" do
      sign_in user

      expect(response).to redirect_to(index_path)
      expect(session[:user_id]).to eq(user.id)
      expect(flash[:success]).to eq("Successfully logged in.")
    end

    it "rejects a wrong password" do
      sign_in user, password: "wrong-password"

      expect(response).to redirect_to(login_path)
      expect(session[:user_id]).to be_nil
      expect(flash[:error]).to eq("Email or password incorrect.")
    end

    it "rejects an unknown email" do
      post login_path, params: { email: "nobody@kbnf.org", password: "1234567890" }

      expect(response).to redirect_to(login_path)
      expect(session[:user_id]).to be_nil
    end

    it "does not keep a deactivated user signed in" do
      sign_in create(:user, status: "Deactivated")

      expect(response).to redirect_to(login_path)
      expect(session[:user_id]).to be_nil
      expect(flash[:success]).to match(/administrator must approve/)
    end
  end

  describe "GET /logout" do
    it "clears the session" do
      sign_in user
      get logout_path

      expect(response).to redirect_to(login_path)
      expect(session[:user_id]).to be_nil
    end
  end

  describe "authorization" do
    it "redirects guests to the login page" do
      get index_path
      expect(response).to redirect_to(login_path)
    end

    it "redirects guests away from protected resources" do
      get warehouses_path
      expect(response).to redirect_to(login_path)
    end

    it "lets an admin view warehouses" do
      sign_in create(:user, status: "Active", role: "Admin")
      get warehouses_path
      expect(response).to have_http_status(:ok)
    end

    it "omits the latest container and shipment links when none exist" do
      sign_in create(:user, status: "Active", role: "Admin")
      get warehouses_path

      expect(response.body).not_to include("Latest Container")
      expect(response.body).not_to include("Latest Shipment")
    end

    it "links to the latest container and shipment" do
      create :container, shipment: nil
      latest_shipment = create :shipment
      latest_container = create :container, shipment: latest_shipment
      sign_in create(:user, status: "Active", role: "Admin")
      get warehouses_path

      expect(response.body).to include(container_path(latest_container))
      expect(response.body).to include(shipment_path(latest_shipment))
    end

    it "turns volunteers away from warehouses with an error" do
      sign_in user
      get warehouses_path

      expect(response).to redirect_to(login_path)
      expect(flash[:error]).to eq("This action is not permitted with your user role.")
    end
  end
end
