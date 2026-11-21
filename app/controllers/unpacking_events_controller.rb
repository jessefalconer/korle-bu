# frozen_string_literal: true

class UnpackingEventsController < ApplicationController
  before_action :set_warehouse_id

  def index
    authorize! :read, UnpackingEvent
    @events = UnpackingEvent.includes(:hospital, :user, packed_item: %i[item box pallet container]).joins(:hospital)
      .where(hospitals: { warehouse_id: current_user.warehouse_id })
      .order(created_at: :desc)
      .page params[:page]
  end

  def update
    event = UnpackingEvent.find(params.expect(:id))
    authorize! :update, event

    if event.update(unpacking_event_params)
      flash[:success] = "Timestamp updated."
    else
      flash[:error] = "Failed to update timestamp."
    end

    redirect_back_or_to(unpacking_events_path)
  end

  private

  def unpacking_event_params
    params.expect(unpacking_event: [:timestamp])
  end

  def set_warehouse_id
    @warehouse_id = current_user.warehouse_id
  end
end
