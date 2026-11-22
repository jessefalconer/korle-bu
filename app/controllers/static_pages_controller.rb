# frozen_string_literal: true

# Serves the standalone HTML pages in public/ (privacy, help pages)
# at extension-less URLs such as /privacy. They are public: no login needed.
class StaticPagesController < ApplicationController
  PAGES = %w[help privacy dev_updates].freeze

  skip_before_action :authorized
  skip_before_action :require_password_change
  skip_authorization_check

  def show
    page = params.require(:page)
    raise ActionController::RoutingError, "Not Found" unless PAGES.include?(page)

    send_file Rails.public_path.join("#{page}.html"), type: "text/html", disposition: "inline"
  end
end
