# frozen_string_literal: true

class BasePresenter < SimpleDelegator
  include ActionView::Helpers
  include ActionView::Context
  include Haml::Helpers
  include Rails.application.routes.url_helpers

  def initialize(model, view)
    @view = view
    super(model)
  end

  def h
    @view
  end
end
