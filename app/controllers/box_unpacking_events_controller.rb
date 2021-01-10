# frozen_string_literal: true

class BoxUnpackingEventsController < ApplicationController
  before_action :set_packed_item
  before_action :set_unpacking_event, only: %i[destroy update]

  def create
    @packed_item.unpacking_events.create(unpacking_event_params.merge(user: current_user))
    redirect_to box_box_items_path(@packed_item.box), flash: { success: "Item unpacked!" }
  end

  def update
    @unpacking_event.update(unpacking_event_params)
    redirect_to box_box_items_path(@box), flash: { success: "Item updated!" }
  end

  def destroy
    @unpacking_event.destroy
    redirect_to box_box_items_path(@unpacking_event.packed_item.box)
  end

  private

  def unpacking_event_params
    params.require(:unpacking_event).permit(:quantity, :box_item_id, :user)
  end

  def set_unpacking_event
    @unpacking_event = UnpackingEvent.find(params[:id])
  end

  def set_packed_item
    @packed_item = PackedItem.find(params[:box_item_id])
  end
end
