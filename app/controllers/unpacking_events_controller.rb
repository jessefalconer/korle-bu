# frozen_string_literal: true

class UnpackingEventsController < ApplicationController
  before_action :set_warehouse_id

  def index
    @events = UnpackingEvent.includes(:hospital, packed_item: :item).joins(:hospital)
      .where("hospitals.warehouse_id = ?", current_user.warehouse_id)
      .order(created_at: :desc)
      .page params[:page]
  end

  def update
    event = UnpackingEvent.find(params[:id])

    if event.update(unpacking_event_params)
      flash[:success] = "Timestamp updated."
    else
      flash[:error] = "Failed to update timestamp."
    end

    redirect_back fallback_location: request.referer
  end

  private

  def unpacking_event_params
    params.require(:unpacking_event).permit(:timestamp)
  end

  def set_warehouse_id
    @warehouse_id = current_user.warehouse_id
  end
end
