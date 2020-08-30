# frozen_string_literal: true

class PalletizedItemsController < ApplicationController
  before_action :set_pallet
  before_action :set_palletized_item, except: %i[create manage add_with_item]

  def create
    @pallet.palletized_items.create(palletized_item_params.merge(user: current_user))
    redirect_to pallet_manage_items_path(@pallet), flash: { success: "Item added!" }
  end

  def update
    @pallet.update(palletized_item_params)
    redirect_to pallet_manage_items_path(@pallet), flash: { success: "Item updated!" }
  end

  def manage
  end

  def add_with_item
    item = Item.new(item_params.merge(user: current_user))

    if item.save
      @pallet.palletized_items.create(expiry_date: params[:expiry_date], quantity: params[:quantity], user: current_user, item_id: item.id)
      redirect_to pallet_manage_items_path(@pallet), flash: { success: "Item created and added!" }
    else
      redirect_to pallet_manage_items_path(@pallet), flash: { error: item.errors }
    end
  end

  def destroy
    @palletized_item.destroy
    redirect_to pallet_manage_items_path(@pallet)
  end

  private

  def palletized_item_params
    params.require(:palletized_item).permit(:expiry_date, :quantity, :item_id)
  end

  def item_params
    params.require(:item).permit(:brand, :object, :standardized_size, :concentration, :concentration_units, :concentration_description, :numerical_size_1, :numerical_units_1, :numerical_description_1, :numerical_size_2, :numerical_units_2, :numerical_description_2, :packaged_quantity, :category_id, :notes, :verified)
  end

  def set_palletized_item
    @palletized_item = PalletizedItem.find(params[:id])
  end

  def set_pallet
    @pallet = Pallet.find(params[:pallet_id])
  end
end
