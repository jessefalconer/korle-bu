# frozen_string_literal: true

class SessionsController < ApplicationController
  skip_before_action :authorized, only: %i[new create]
  before_action :existing_session, only: %i[new create]

  def new
  end

  def create
    @user = User.find_by(email: params[:email])
    if @user&.authenticate(params[:password])
      session[:user_id] = @user.id
      if @user.status == "Deactivated"
        redirect_to login_path, flash: { success: "Your account has been created, however an administrator must approve it. Please check back later." }
        session.clear
      else
        redirect_to index_path, flash: { success: "Successfully logged in." }
      end
    else
      redirect_to login_path, flash: { error: "Email or password incorrect." }
    end
  end

  def destroy
    session.clear
    redirect_to login_path, flash: { success: "Successfully logged out." }
  end

  def login
  end

  def index
  end

  def my_activity
    @boxes = current_user.boxes.where("boxes.created_at > ?", 30.days.ago).order(:updated_at).reverse_order
    @box_items = current_user.box_items.where("packed_items.created_at > ?", 30.days.ago).order(:updated_at).reverse_order
    @pallets = current_user.pallets.where("pallets.created_at > ?", 30.days.ago).order(:updated_at).reverse_order
    @pallet_items = current_user.pallet_items.where("packed_items.created_at > ?", 30.days.ago).order(:updated_at).reverse_order
    @containers = current_user.containers.where("containers.created_at > ?", 30.days.ago).order(:updated_at).reverse_order
    @container_items = current_user.container_items.where("packed_items.created_at > ?", 30.days.ago).order(:updated_at).reverse_order
  end

  private

  def existing_session
    redirect_to index_path if logged_in?
  end
end
