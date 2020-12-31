# frozen_string_literal: true

class ContainerItemsController < ApplicationController
  before_action :set_container
  before_action :set_container_item, except: %i[create index add_with_item]

  def create
    @container.container_items.create(container_item_params.merge(user: current_user))
    redirect_to container_container_items_path(@container), flash: { success: "Item added!" }
  end

  def update
    @container_item.update(container_item_params)
    redirect_to container_container_items_path(@container), flash: { success: "Item updated!" }
  end

  def index
  end

  def add_with_item
    item = Item.new(item_params.merge(user: current_user))

    if item.save
      @container.container_items.create(expiry_date: params[:expiry_date], quantity: params[:quantity], user: current_user, item_id: item.id)
      redirect_to container_container_items_path(@container), flash: { success: "Item created and added!" }
    else
      redirect_to container_container_items_path(@container), flash: { error: item.errors }
    end
  end

  def destroy
    @container_item.destroy
    redirect_to container_container_items_path(@container)
  end

  private

  def container_item_params
    params.require(:packed_item).permit(:expiry_date, :quantity, :item_id)
  end

  def item_params
    params.require(:item).permit(:brand, :object, :standardized_size, :concentration, :concentration_units, :concentration_description, :numerical_size_1, :numerical_units_1, :numerical_description_1, :numerical_size_2, :numerical_units_2, :numerical_description_2, :packaged_quantity, :category_id, :notes, :verified)
  end

  def set_container_item
    @container_item = PackedItem.find(params[:id])
  end

  def set_container
    @container = Container.find(params[:container_id])
  end
end
