# frozen_string_literal: true

class UnpackingEventsController < ApplicationController
  before_action :set_warehouse_id

  def index
    @events = UnpackingEvent.joins(:hospital)
                            .where("hospitals.warehouse_id = ?", current_user.warehouse_id)
                            .order(:created_at)
                            .reverse_order
                            .page params[:page]
  end

  private

  def set_warehouse_id
    @warehouse_id = current_user.warehouse_id
  end
end
