# frozen_string_literal: true

class UsersController < ApplicationController
  load_and_authorize_resource except: %i[signup create_public_user]
  skip_before_action :authorized, only: %i[new signup create_public_user]
  before_action :set_user, only: %i[show destroy update]
  before_action :existing_session, only: %i[signup create_public_user]

  def new
    @user = User.new
  end

  def index
    @users = User.all.page params[:page]
  end

  def show
  end

  def update
    if @user.update(user_params)
      redirect_to user_path(@user), flash: { success: "User update successful." }
    else
      redirect_to user_path(@user), flash: { error: @user.errors.full_messages.to_sentence }
    end
  end

  def destroy
    redirect_to user_path(@user), flash: { error: "#{@user.name} cannot be deleted. Instead, switch their status to Deactivated." }
  end

  def signup
    @user = User.new
  end

  def create_public_user
    @user = User.create(user_params)
    if @user.errors.any?
      redirect_to signup_path, flash: { error: @user.errors.full_messages.to_sentence }
    else
      session[:user_id] = @user.id
      redirect_to index_path, flash: { success: "User creation successful." }
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :last_name, :first_name, :phone, :role, :status, :notes, :warehouse_id)
  end

  def existing_session
    redirect_to index_path if logged_in?
  end

  def set_user
    @user = User.find(params[:id])
  end
end
