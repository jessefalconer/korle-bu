# frozen_string_literal: true

class PalletItemsController < ApplicationController
  before_action :set_pallet
  before_action :set_pallet_item, except: %i[create index add_with_item]

  def create
    @pallet.pallet_items.create(pallet_item_params.merge(user: current_user))
    redirect_to pallet_pallet_items_path(@pallet), flash: { success: "Item added." }
  end

  def update
    @pallet_item.update(pallet_item_params)
    redirect_to pallet_pallet_items_path(@pallet), flash: { success: "Item updated." }
  end

  def index
  end

  def add_with_item
    item = Item.new(item_params.merge(user: current_user))

    if item.save
      @pallet.pallet_items.create(expiry_date: params[:expiry_date], quantity: params[:quantity], user: current_user, item_id: item.id)
      redirect_to pallet_pallet_items_path(@pallet), flash: { success: "Item created and added." }
    else
      redirect_to pallet_pallet_items_path(@pallet), flash: { error: item.errors }
    end
  end

  def destroy
    @pallet_item.destroy
    redirect_to pallet_pallet_items_path(@pallet)
  end

  private

  def pallet_item_params
    params.require(:packed_item).permit(:expiry_date, :quantity, :item_id, :weight)
  end

  def item_params
    params.require(:item).permit(:brand, :object, :standardized_size,
                                 :numerical_size_1, :numerical_units_1, :numerical_description_1, :numerical_size_2, :numerical_units_2, :numerical_description_2,
                                 :area_1, :area_2, :area_units, :area_description, :range_1, :range_2, :range_units, :range_description, :packaged_quantity, :unit_weight,
                                 :category_id, :notes, :verified, :photo, :flagged)
  end

  def set_pallet_item
    @pallet_item = PackedItem.find(params[:id])
  end

  def set_pallet
    @pallet = Pallet.find(params[:pallet_id])
  end
end
