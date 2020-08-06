# frozen_string_literal: true

class UsersController < ApplicationController
  skip_before_action :authorized, only: %i[new create]

  def new
    @user = User.new
  end

  def create
    @user = User.create(user_params)
    if @user.errors.any?
      message = { error: @user.errors.full_messages.to_sentence }
    else
      session[:user_id] = @user.id
      message = { success: "User creation successful." }
    end

    redirect_to :root, flash: message
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :last_name, :first_name)
  end
end
