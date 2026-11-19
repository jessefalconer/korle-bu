# frozen_string_literal: true

require "rails_helper"

describe "Passwords", type: :request do
  let(:admin) { create :user, status: "Active", role: "Admin" }

  def change_own_password(current:, new_password:, confirmation: new_password)
    patch password_path, params: { current_password: current, password: new_password, password_confirmation: confirmation }
  end

  describe "accounts created by an admin" do
    let(:params) do
      {
        user: {
          email: "volunteer@kbnf.org", first_name: "Ama", last_name: "Mensah", phone: "604-555-0101",
          password: "temporary1", password_confirmation: "temporary1", role: "Volunteer", status: "Active"
        }
      }
    end

    it "start with a temporary password that must be changed" do
      sign_in admin
      post users_path, params: params

      expect(User.find_by!(email: "volunteer@kbnf.org").must_change_password).to be(true)
    end

    it "reject a temporary password shorter than 8 characters" do
      sign_in admin
      short = params.deep_merge(user: { password: "temp123", password_confirmation: "temp123" })

      expect { post users_path, params: short }.not_to change(User, :count)
      expect(flash[:error]).to include("too short")
    end
  end

  describe "a user with a temporary password" do
    let(:user) { create :user, status: "Active", role: "Volunteer", password: "temporary1", must_change_password: true }

    it "is sent to the change-password page on login" do
      sign_in user, password: "temporary1"

      expect(response).to redirect_to(edit_password_path)
    end

    it "cannot use the rest of the app until they change it" do
      sign_in user, password: "temporary1"
      get index_path

      expect(response).to redirect_to(edit_password_path)
    end

    it "can still log out" do
      sign_in user, password: "temporary1"
      get logout_path

      expect(response).to redirect_to(login_path)
      expect(session[:user_id]).to be_nil
    end

    it "is released once they choose their own password" do
      sign_in user, password: "temporary1"
      change_own_password(current: "temporary1", new_password: "my-own-pass")

      expect(response).to redirect_to(index_path)
      user.reload
      expect(user.must_change_password).to be(false)
      expect(user.authenticate("my-own-pass")).to be_truthy

      get index_path
      expect(response).to have_http_status(:ok)
    end

    it "must choose a different password from the temporary one" do
      sign_in user, password: "temporary1"
      change_own_password(current: "temporary1", new_password: "temporary1")

      expect(response).to have_http_status(:unprocessable_content)
      expect(user.reload.must_change_password).to be(true)
    end
  end

  describe "changing your own password" do
    User::ROLES.each do |role|
      it "works for a #{role}" do
        user = create :user, status: "Active", role: role
        sign_in user
        change_own_password(current: "1234567890", new_password: "brand-new-pass")

        expect(response).to redirect_to(index_path)
        expect(user.reload.authenticate("brand-new-pass")).to be_truthy
      end
    end

    it "requires the current password" do
      user = create :user, status: "Active"
      sign_in user
      change_own_password(current: "wrong-password", new_password: "brand-new-pass")

      expect(response).to have_http_status(:unprocessable_content)
      expect(user.reload.authenticate("brand-new-pass")).to be(false)
    end

    it "requires at least 8 characters" do
      user = create :user, status: "Active"
      sign_in user
      change_own_password(current: "1234567890", new_password: "short12")

      expect(response).to have_http_status(:unprocessable_content)
      expect(user.reload.authenticate("short12")).to be(false)
    end

    it "requires the confirmation to match" do
      user = create :user, status: "Active"
      sign_in user
      change_own_password(current: "1234567890", new_password: "brand-new-pass", confirmation: "different-pass")

      expect(response).to have_http_status(:unprocessable_content)
      expect(user.reload.authenticate("brand-new-pass")).to be(false)
    end

    it "requires logging in" do
      get edit_password_path

      expect(response).to redirect_to(login_path)
    end
  end

  describe "an admin resetting someone's password" do
    it "sets a temporary password the user must change at next login" do
      user = create :user, status: "Active", role: "Volunteer"
      sign_in admin
      patch change_password_user_path(user), params: { user: { password: "reset-temp-1", password_confirmation: "reset-temp-1" } }

      user.reload
      expect(user.authenticate("reset-temp-1")).to be_truthy
      expect(user.must_change_password).to be(true)
    end
  end

  describe "existing users with shorter passwords" do
    it "can still log in normally" do
      user = create :user, status: "Active"
      user.update_column(:password_digest, BCrypt::Password.create("123456", cost: BCrypt::Engine::MIN_COST))
      sign_in user, password: "123456"

      expect(response).to redirect_to(index_path)
    end
  end
end
