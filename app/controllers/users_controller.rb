# frozen_string_literal: true

class UsersController < ApplicationController
  load_and_authorize_resource except: %i[signup create_public_user]
  skip_before_action :authorized, only: %i[new signup create_public_user]
  before_action :set_user, only: %i[show destroy update change_password]
  before_action :existing_session, only: %i[signup create_public_user]

  def new
    @user = User.new
  end

  def index
    @users = if params[:warehouse]
      User.where(warehouse_id: params[:warehouse]).page params[:page]
    else
      User.all.page params[:page]
    end
  end

  def create
    user = User.create(user_params)
    if user.errors.any?
      redirect_to new_user_path,
        flash: { error: user.errors.full_messages.to_sentence }
    else
      redirect_to users_path, flash: { success: "User created." }
    end
  end

  def show
  end

  def update
    if @user.update(user_params)
      redirect_to user_path(@user), flash: { success: "User updated." }
    else
      redirect_to user_path(@user),
        flash: { error: @user.errors.full_messages.to_sentence }
    end
  end

  def change_password
    if @user.update(user_params)
      redirect_to user_path(@user), flash: { success: "Password updated." }
    else
      redirect_to user_path(@user),
        flash: { error: @user.errors.full_messages.to_sentence }
    end
  end

  def destroy
    @user.destroy
    redirect_to users_path, flash: { success: "#{@user.name} deleted." }
  end

  def signup
    @user = User.new
  end

  def create_public_user
    @user = User.create(user_params)
    if @user.errors.any?
      redirect_to signup_path,
        flash: { error: @user.errors.full_messages.to_sentence }
    else
      redirect_to login_path,
        flash: { success: "User created, waiting for administrator approval." }
    end
  end

  private

  def user_params
    params.require(:user)
      .permit(
        :email, :password, :password_confirmation, :last_name, :first_name,
        :phone, :role, :status, :notes, :warehouse_id, :achiever_name,
        :achievement_title, :achievement_description, :achievement_value,
        :achievement_max_value
      )
  end

  def existing_session
    redirect_to index_path if logged_in?
  end

  def set_user
    @user = User.find(params[:id])
  end
end
