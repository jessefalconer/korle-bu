# frozen_string_literal: true

class BoxedItemsController < ApplicationController
  before_action :set_path, only: %i[update create]

  def new
  end

  def create
    @box.boxed_items.create(boxed_item_params.merge(user: current_user))
    redirect_to shipment_container_pallet_box_path(@shipment, @container, @pallet, @box), flash: { success: "Saved!" }
  end

  def index
  end

  def show
  end

  def edit
  end

  def update
    @box.update(boxed_item_params)
    redirect_to shipment_container_pallet_box_path(@shipment, @container, @pallet, @box), flash: { success: "Saved!" }
  end

  def destroy
  end

  private

  def boxed_item_params
    params.require(:box).permit(:user, :item_id, :expiry_date, :quantity, boxed_items_attributes: %i[id item_id expiry_date quantity _destroy])
  end

  def set_path
    @box = Box.find(params[:box_id])
    @pallet = @box.pallet
    @container = @pallet.container
    @shipment = @container.shipment
  end
end
