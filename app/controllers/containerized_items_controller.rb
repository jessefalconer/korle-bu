# frozen_string_literal: true

class ContainerizedItemsController < ApplicationController
  before_action :set_container
  before_action :set_containerized_item, except: %i[create manage add_with_item]

  def create
    @container.containerized_items.create(containerized_item_params.merge(user: current_user))
    redirect_to container_manage_items_path(@container), flash: { success: "Item added!" }
  end

  def update
    @container.update(containerized_item_params)
    redirect_to container_manage_items_path(@container), flash: { success: "Item updated!" }
  end

  def manage
  end

  def add_with_item
    item = Item.new(item_params.merge(user: current_user))

    if item.save
      @container.containerized_items.create(expiry_date: params[:expiry_date], quantity: params[:quantity], user: current_user, item_id: item.id)
      redirect_to container_manage_items_path(@container), flash: { success: "Item created and added!" }
    else
      redirect_to container_manage_items_path(@container), flash: { error: item.errors }
    end
  end

  def destroy
    @containerized_item.destroy
    redirect_to container_manage_items_path(@container)
  end

  private

  def containerized_item_params
    params.require(:container).permit(:expiry_date, :quantity, :item_id)
  end

  def item_params
    params.require(:item).permit(:brand, :object, :standardized_size, :concentration, :concentration_units, :concentration_description, :numerical_size_1, :numerical_units_1, :numerical_description_1, :numerical_size_2, :numerical_units_2, :numerical_description_2, :packaged_quantity, :category_id, :notes, :verified)
  end

  def set_containerized_item
    @containerized_item = ContainerizedItem.find(params[:id])
  end

  def set_container
    @container = Container.find(params[:container_id])
  end
end
