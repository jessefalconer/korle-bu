# frozen_string_literal: true

class BoxedItemsController < ApplicationController
  before_action :set_box
  before_action :set_boxed_item, except: %i[create manage add_with_item]

  def create
    @box.boxed_items.create(boxed_item_params.merge(user: current_user))
    redirect_to box_manage_items_path(@box), flash: { success: "Item added!" }
  end

  def update
    @boxed_item.update(boxed_item_params)
    redirect_to box_manage_items_path(@box), flash: { success: "Item updated!" }
  end

  def manage
  end

  def add_with_item
    item = Item.new(item_params.merge(user: current_user))

    if item.save
      @box.boxed_items.create(expiry_date: params[:expiry_date], quantity: params[:quantity], user: current_user, item_id: item.id)
      redirect_to box_manage_items_path(@box), flash: { success: "Item created and added!" }
    else
      redirect_to box_manage_items_path(@box), flash: { error: item.errors }
    end
  end

  def destroy
    @boxed_item.destroy
    redirect_to box_manage_items_path(@box)
  end

  private

  def boxed_item_params
    params.require(:boxed_item).permit(:expiry_date, :quantity, :item_id)
  end

  def item_params
    params.require(:item).permit(:brand, :object, :standardized_size, :concentration, :concentration_units, :concentration_description, :numerical_size_1, :numerical_units_1, :numerical_description_1, :numerical_size_2, :numerical_units_2, :numerical_description_2, :packaged_quantity, :category_id, :notes, :verified)
  end

  def set_boxed_item
    @boxed_item = BoxedItem.find(params[:id])
  end

  def set_box
    @box = Box.find(params[:box_id])
  end
end
