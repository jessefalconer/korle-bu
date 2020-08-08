# frozen_string_literal: true

class UsersController < ApplicationController
  skip_before_action :authorized, only: %i[new create]
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

  private

  def user_params
    params.require(:user).permit(:email, :password, :last_name, :first_name)
  end

  def existing_session
    redirect_to index_path if logged_in?
  end
end
