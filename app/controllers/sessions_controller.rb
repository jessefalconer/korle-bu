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
        redirect_to :root, flash: { success: "Your account has been created, however an administrator must approve it. Please check back later." }
        session.clear
      else
        redirect_to index_path, flash: { success: "Successfully logged in." }
      end
    else
      redirect_to :root, flash: { error: "Email or password incorrect." }
    end
  end

  def destroy
    session.clear
    redirect_to :root, flash: { success: "Successfully logged out." }
  end

  def login
  end

  def index
  end

  def my_activity
    @boxes = current_user.boxes.order(:created_at)
    @box_items = PackedItem.where(user: current_user, box_id: @boxes.ids).order(:created_at)
    @pallets = current_user.pallets.order(:created_at)
    @pallet_items = PackedItem.where(user: current_user, pallet_id: @pallets.ids).order(:created_at)
    @containers = current_user.containers.order(:created_at)
    @container_items = PackedItem.where(user: current_user, container_id: @containers.ids).order(:created_at)
  end

  private

  def existing_session
    redirect_to index_path if logged_in?
  end
end
