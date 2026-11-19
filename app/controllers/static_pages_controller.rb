# frozen_string_literal: true

# Serves the standalone HTML pages in public/ (privacy, terms, help pages)
# at extension-less URLs such as /privacy. They are public: no login needed.
class StaticPagesController < ApplicationController
  PAGES = %w[privacy terms admin_help volunteer_help dev_updates].freeze

  skip_before_action :authorized
  skip_before_action :require_password_change

  def show
    page = params.require(:page)
    raise ActionController::RoutingError, "Not Found" unless PAGES.include?(page)

    send_file Rails.public_path.join("#{page}.html"), type: "text/html", disposition: "inline"
  end
end
