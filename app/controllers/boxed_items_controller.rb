# frozen_string_literal: true

class BoxedItemsController < ApplicationController
  def new
  end

  def create
  end

  def index
  end

  def show
  end

  def edit
  end

  def update
  end

  def destroy
  end

  private

  def boxed_item_params
    params.require(:boxed_item).permit(:boxed_item_id, :box_id, :item_id)
  end

  def set_box
    @box = Box.find(params[:id])
  end

  def set_pallet
    @pallet = Pallet.find(params[:pallet_id])
  end

  def set_container
    @container = Container.find(params[:container_id])
  end

  def set_shipment
    @shipment = Shipment.find(params[:shipment_id])
  end
end
