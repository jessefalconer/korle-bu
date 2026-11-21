# frozen_string_literal: true

class UsersController < ApplicationController
  PROFILE_FIELDS = %i[
    email first_name last_name phone notes achiever_name achievement_title
    achievement_description achievement_value achievement_max_value
  ].freeze
  PASSWORD_FIELDS = %i[password password_confirmation].freeze
  # Only people allowed to manage roles may set these (the form hides them for
  # everyone else; this enforces it on the server too).
  ROLE_FIELDS = %i[role status warehouse_id].freeze

  load_and_authorize_resource
  before_action :set_user, only: %i[show destroy update change_password]
  before_action :forbid_admin_role_grant, only: %i[create update]

  def index
    @users = if params[:warehouse]
      User.where(warehouse_id: params[:warehouse]).page params[:page]
    else
      User.all.page params[:page]
    end
  end

  def show
  end

  def new
    @user = User.new
  end

  def create
    # The admin sets a temporary password; the new user must replace it at first login.
    user = User.create(user_params.merge(must_change_password: true))
    if user.errors.any?
      redirect_to new_user_path,
                  flash: { error: user.errors.full_messages.to_sentence }
    else
      redirect_to users_path, flash: { success: "User created." }
    end
  end

  def update
    if @user.update(user_params)
      redirect_to user_path(@user), flash: { success: "User updated." }
    else
      redirect_to user_path(@user),
                  flash: { error: @user.errors.full_messages.to_sentence }
    end
  end

  # Admins and Shipping Managers resetting someone else's password: it becomes a
  # temporary password the user must replace at next login. (People change their
  # own password through PasswordsController, which asks for the current one.)
  def change_password
    resetting_someone_else = @user != current_user
    if @user.update(password_params.merge(must_change_password: resetting_someone_else))
      notice = resetting_someone_else ? "Temporary password set. #{@user.first_name} must choose a new one at next login." : "Password updated."
      redirect_to user_path(@user), flash: { success: notice }
    else
      redirect_to user_path(@user),
                  flash: { error: @user.errors.full_messages.to_sentence }
    end
  end

  def destroy
    @user.destroy
    redirect_to users_path, flash: { success: "#{@user.name} deleted." }
  end

  private

  # Used for create/update, including by CanCanCan's load_and_authorize_resource.
  def user_params
    permitted = PROFILE_FIELDS.dup
    permitted += PASSWORD_FIELDS if action_name == "create"
    permitted += ROLE_FIELDS if can_alter_roles?
    params.expect(user: [*permitted])
  end

  def password_params
    params.expect(user: [*PASSWORD_FIELDS])
  end

  # Mirrors the condition in users/_form: role managers, or a "masquerader"
  # (a tester who may switch their own role) editing their own account.
  def can_alter_roles?
    return false unless logged_in?

    can?(:alter_roles, User) || masquerading_self?
  end

  # Only Admins may hand out the Admin role. Masqueraders can switch their own
  # role to test the app, but not to Admin.
  def forbid_admin_role_grant
    return unless params.dig(:user, :role) == "Admin" && can_alter_roles?
    return if current_user.admin?

    raise CanCan::AccessDenied
  end

  def masquerading_self?
    current_user.masquerader && params[:id].to_s == current_user.id.to_s
  end

  def set_user
    @user = User.find(params.expect(:id))
  end
end
