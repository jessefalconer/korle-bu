# frozen_string_literal: true

class PalletizedItemsController < ApplicationController
  before_action :set_pallet, only: %i[update create]

  def create
    @pallet.palletized_items.create(palletized_item_params.merge(user: current_user))
    redirect_to pallet_path(@pallet), flash: { success: "Saved!" }
  end

  def update
    @pallet.update(boxed_item_params)
    redirect_to pallet_path(@pallet), flash: { success: "Saved!" }
  end

  def destroy
  end

  private

  def palletized_item_params
    params.require(:pallet).permit(:user, :item_id, :expiry_date, :quantity, boxed_items_attributes: %i[id item_id expiry_date quantity _destroy])
  end

  def set_pallet
    @pallet = Pallet.find(params[:pallet_id])
  end
end
