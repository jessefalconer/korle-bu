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
    if @user.update(password_params)
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
    # Public sign-ups always start as a deactivated Volunteer awaiting approval;
    # role and status are never taken from the request.
    @user = User.create(public_signup_params.merge(role: "Volunteer", status: "Deactivated"))
    if @user.errors.any?
      redirect_to signup_path,
        flash: { error: @user.errors.full_messages.to_sentence }
    else
      redirect_to login_path,
        flash: { success: "User created, waiting for administrator approval." }
    end
  end

  private

  PROFILE_FIELDS = %i[
    email first_name last_name phone notes achiever_name achievement_title
    achievement_description achievement_value achievement_max_value
  ].freeze
  PASSWORD_FIELDS = %i[password password_confirmation].freeze
  # Only people allowed to manage roles may set these (the form hides them for
  # everyone else; this enforces it on the server too).
  ROLE_FIELDS = %i[role status warehouse_id].freeze

  # Used for create/update, including by CanCanCan's load_and_authorize_resource.
  def user_params
    permitted = PROFILE_FIELDS.dup
    permitted += PASSWORD_FIELDS if action_name == "create"
    permitted += ROLE_FIELDS if can_alter_roles?
    params.require(:user).permit(*permitted)
  end

  def password_params
    params.require(:user).permit(*PASSWORD_FIELDS)
  end

  def public_signup_params
    params.require(:user).permit(:email, :first_name, :last_name, :phone, *PASSWORD_FIELDS)
  end

  # Mirrors the condition in users/_form: role managers, or a "masquerader"
  # (a tester who may switch their own role) editing their own account.
  def can_alter_roles?
    return false unless logged_in?

    can?(:alter_roles, User) ||
      (current_user.masquerader && params[:id].to_s == current_user.id.to_s)
  end

  def existing_session
    redirect_to index_path if logged_in?
  end

  def set_user
    @user = User.find(params[:id])
  end
end
