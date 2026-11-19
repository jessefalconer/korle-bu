# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :authorized
  helper_method :current_user
  helper_method :logged_in?

  rescue_from CanCan::AccessDenied do |_exception|
    redirect_back fallback_location: login_path,
      flash: { error: "This action is not permitted with your user role." }
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

  def authorized
    redirect_to login_path unless logged_in?
  end
end
