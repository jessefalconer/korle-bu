# frozen_string_literal: true

class PackedItemsController < ApplicationController
  before_action :set_packed_item, except: %i[create index add_with_item]

  def create
    @packed_item = PackedItem.create(packed_item_params.merge(user: current_user))
    redirect_to packed_items_path, flash: { success: "Item added." }
  end

  def update
    if @packed_item.update(packed_item_params)
      redirect_to packed_items_path, flash: { success: "Item updated." }
    else
      redirect_to packed_items_path, flash: { error: @packed_item.errors.full_messages.to_sentence }
    end
  end

  def index
    @boxes = Box.in_progress.order(:name)
    @pallets = Pallet.in_progress.order(:name)
    @containers = Container.in_progress.order(:name)
    @packed_items = PackedItem.staged.page params[:page]
  end

  def add_with_item
    item = Item.new(item_params.merge(user: current_user))

    if item.save
      PackedItem.create(expiry_date: params[:expiry_date], quantity: params[:quantity], user: current_user, item_id: item.id)
      redirect_to packed_items_path, flash: { success: "Item created and added." }
    else
      redirect_to packed_items_path, flash: { error: item.errors.full_messages.to_sentence }
    end
  end

  def destroy
    @packed_item.destroy
    redirect_to packed_items_path
  end

  private

  def packed_item_params
    params.require(:packed_item).permit(:expiry_date, :quantity, :item_id, :weight, :box_id, :pallet_id, :container_id, :staged)
  end

  def item_params
    params.require(:item).permit(:brand, :object, :standardized_size,
                                 :numerical_size_1, :numerical_units_1, :numerical_description_1, :numerical_size_2, :numerical_units_2, :numerical_description_2,
                                 :area_1, :area_2, :area_units, :area_description, :range_1, :range_2, :range_units, :range_description, :unit_weight,
                                 :category_id, :notes, :verified, :photo, :flagged)
  end

  def set_packed_item
    @packed_item = PackedItem.find(params[:id])
  end
end
