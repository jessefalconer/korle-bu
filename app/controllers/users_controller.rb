# frozen_string_literal: true

class UsersController < ApplicationController
  skip_before_action :authorized, only: %i[new create]
  before_action :set_user, only: %i[show destroy edit update]
  before_action :existing_session, only: %i[new create]

  def new
    @user = User.new
  end

  def create
    @user = User.create(user_params)
    if @user.errors.any?
      redirect_to new_user_path, flash: { error: @user.errors }
    else
      session[:user_id] = @user.id
      redirect_to index_path, flash: { success: "User creation successful." }
    end
  end

  def index
    @users = User.all
  end

  def show
  end

  def destroy
    @user.destroy
    redirect_to users_path
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :last_name, :first_name)
  end

  def existing_session
    redirect_to index_path if logged_in?
  end

  def set_user
    @user = User.find(params[:id])
  end
end
