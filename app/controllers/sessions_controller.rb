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
      redirect_to index_path, flash: { success: "Successfully logged in." }
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
    @boxes = Box.where(user: current_user).order(:created_at).reverse
    @boxed_items = BoxedItem.where(user: current_user).order(:created_at).reverse
    @pallets = Pallet.where(user: current_user).order(:created_at).reverse
    @palletized_items = PalletizedItem.where(user: current_user).order(:created_at).reverse
    @containers = Container.where(user: current_user).order(:created_at).reverse
    @containerized_items = ContainerizedItem.where(user: current_user).order(:created_at).reverse
  end

  private

  def existing_session
    redirect_to index_path if logged_in?
  end
end
