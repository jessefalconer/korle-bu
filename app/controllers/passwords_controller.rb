# frozen_string_literal: true

# Lets the signed-in user change their own password. Also where users land
# when they must replace a temporary password set by an admin.
class PasswordsController < ApplicationController
  skip_before_action :require_password_change
  # Only ever acts on current_user, after checking their current password.
  skip_authorization_check

  def edit
  end

  def update
    error = password_change_error
    if error
      flash.now[:error] = error
      render :edit, status: :unprocessable_content
      return
    end

    if current_user.update(password: params[:password],
                           password_confirmation: params[:password_confirmation],
                           must_change_password: false)
      redirect_to index_path, flash: { success: "Password changed." }
    else
      flash.now[:error] = current_user.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_content
    end
  end

  private

  def password_change_error
    return "Your current password is incorrect." unless current_user.authenticate(params[:current_password].to_s)
    return "Choose a password different from your current one." if params[:password] == params[:current_password]

    nil
  end
end
