# frozen_string_literal: true

class ContainerUnpackingEventsController < ApplicationController
  before_action :set_packed_item
  before_action :set_unpacking_event, only: :destroy

  def create
    event = @packed_item.unpacking_events
      .create(unpacking_event_params.merge(user: current_user))

    if event.save
      redirect_to container_container_items_path(@packed_item.container),
                  flash: { success: "Unpacking logged." }
    else
      redirect_to container_container_items_path(@packed_item.container),
                  flash: { error: "Unpacking failed: #{event.errors.full_messages.to_sentence}" }
    end
  end

  def destroy
    @unpacking_event.destroy
    redirect_to container_container_items_path(@unpacking_event.packed_item.container)
  end

  private

  def unpacking_event_params
    params.require(:unpacking_event)
      .permit(:quantity, :weight, :notes, :container_item_id, :hospital_id, :timestamp)
  end

  def set_unpacking_event
    @unpacking_event = UnpackingEvent.find(params[:id])
  end

  def set_packed_item
    @packed_item = PackedItem.find(params[:container_item_id])
  end
end
