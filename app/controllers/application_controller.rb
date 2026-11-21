# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :authorized
  before_action :require_password_change
  # Every action must check permissions (authorize! or load_and_authorize_resource),
  # or opt out explicitly with skip_authorization_check. A forgotten check raises.
  check_authorization
  helper_method :current_user
  helper_method :logged_in?

  rescue_from CanCan::AccessDenied do |_exception|
    redirect_back_or_to(login_path, flash: { error: "This action is not permitted with your user role." })
  end

  private

  # Looked up once per request; it's used by views, CanCan abilities and before_actions.
  def current_user
    return @current_user if defined?(@current_user)

    @current_user = User.find_by(id: session[:user_id])
  end

  def logged_in?
    !current_user.nil?
  end

  # Also ends the session of anyone deactivated since they logged in.
  def authorized
    return redirect_to login_path unless logged_in?
    return if current_user.active?

    reset_session
    @current_user = nil
    redirect_to login_path, flash: { error: "This account is deactivated. Please contact a KBNF administrator." }
  end

  # Someone using a temporary password set by an admin can do nothing else
  # until they have chosen their own.
  def require_password_change
    return unless logged_in? && current_user.must_change_password

    redirect_to edit_password_path, flash: { error: "Please choose a new password before continuing." }
  end

  # Index pages accept ?display=<scope> to filter. Only names in `allowed` are
  # ever called, and the name returned comes from that list, never the request.
  def display_scope(allowed)
    allowed.find { |name| name == params[:display] }
  end
end
