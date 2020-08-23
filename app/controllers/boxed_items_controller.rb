# frozen_string_literal: true

class BoxedItemsController < ApplicationController
  before_action :set_box, only: %i[update create]

  def create
    @box.boxed_items.create(boxed_item_params.merge(user: current_user))
    redirect_to box_path(@box), flash: { success: "Saved!" }
  end

  def update
    @box.update(boxed_item_params)
    redirect_to box_path(@box), flash: { success: "Saved!" }
  end

  private

  def boxed_item_params
    params.require(:box).permit(:user, :item_id, :expiry_date, :quantity, boxed_items_attributes: %i[id item_id expiry_date quantity _destroy])
  end

  def set_box
    @box = Box.find(params[:box_id])
  end
end
