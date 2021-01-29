# frozen_string_literal: true

class BoxItemsController < ApplicationController
  before_action :set_box
  before_action :set_box_item, except: %i[create index add_with_item]

  def create
    @box.box_items.create(box_item_params.merge(user: current_user))
    redirect_to box_box_items_path(@box), flash: { success: "Item added." }
  end

  def update
    @box_item.update(box_item_params)
    redirect_to box_box_items_path(@box), flash: { success: "Item updated." }
  end

  def index
  end

  def add_with_item
    item = Item.new(item_params.merge(user: current_user))

    if item.save
      @box.box_items.create(expiry_date: params[:expiry_date], quantity: params[:quantity], user: current_user, item_id: item.id)
      redirect_to box_box_items_path(@box), flash: { success: "Item created and added." }
    else
      redirect_to box_box_items_path(@box), flash: { error: item.errors }
    end
  end

  def destroy
    @box_item.destroy
    redirect_to box_box_items_path(@box)
  end

  private

  def box_item_params
    params.require(:packed_item).permit(:expiry_date, :quantity, :item_id)
  end

  def item_params
    params.require(:item).permit(:brand, :object, :standardized_size, :concentration, :concentration_units, :concentration_description,
      :numerical_size_1, :numerical_units_1, :numerical_description_1, :numerical_size_2, :numerical_units_2, :numerical_description_2,
      :area_1, :area_2, :area_units, :area_description, :range_1, :range_2, :range_units, :range_description, :packaged_quantity,
      :category_id, :notes, :verified, :photo, :flagged)
  end

  def set_box_item
    @box_item = PackedItem.find(params[:id])
  end

  def set_box
    @box = Box.find(params[:box_id])
  end
end
