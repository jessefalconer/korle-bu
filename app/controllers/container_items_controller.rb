# frozen_string_literal: true

class ContainerItemsController < ApplicationController
  before_action :set_container
  before_action :set_container_item, except: %i[create index add_with_item mass_reassign]

  def create
    container_item = @container.container_items.build(container_item_params)

    if container_item.save
      id_sentence = container_item.show_id ? "ID: ##{container_item.id}." : ""
      message = { success: "#{container_item.quantity} #{container_item.generated_name.pluralize} added. #{id_sentence}" }
    else
      message = { error: container_item.errors.full_messages.to_sentence }
    end

    redirect_to container_container_items_path(@container), flash: message
  end

  def update
    if @container_item.update(container_item_params)
      id_sentence = @container_item.show_id ? "ID: ##{@container_item.id}." : ""
      message = { success: "#{@container_item.quantity} #{@container_item.generated_name.pluralize} updated. #{id_sentence}" }
    else
      message = { error: @container_item.errors.full_messages.to_sentence }
    end

    redirect_to container_container_items_path(@container), flash: message
  end

  def index
    @boxes = Box.in_progress.order(:id).reverse_order
    @pallets = Pallet.in_progress.order(:id).reverse_order
    @containers = Container.in_progress.order(:id).reverse_order
  end

  def add_with_item
    item = Item.new(item_params)
    container_item = @container.container_items.build(container_item_params.merge(item: item))

    if item.save && container_item.save
      id_sentence = container_item.show_id ? "ID: ##{container_item.id}." : ""
      message = { success: "Item created. #{container_item.quantity} #{item.generated_name.pluralize} added. #{id_sentence}" }
    else
      error_message = item.errors.full_messages + container_item.errors.full_messages
      message = { error: error_message.to_sentence }
    end

    redirect_to container_container_items_path(@container), flash: message
  end

  def mass_reassign
    if params[:packed_item_ids].nil?
      redirect_to container_path(@container), flash: { error: "No items where selected." }
    else
      PackedItem.where(id: params[:packed_item_ids]).update(container_id: @container.id)
      redirect_to container_path(@container), flash: { success: "Items reassigned." }
    end
  end

  def destroy
    @container_item.destroy
    redirect_to container_container_items_path(@container)
  end

  private

  def container_item_params
    params.require(:packed_item).permit(:expiry_date, :quantity, :item_id, :weight, :box_id, :pallet_id, :container_id, :show_id, :status).merge(user: current_user)
  end

  def item_params
    params.require(:item)
          .permit(:brand, :object, :standardized_size,
                  :numerical_size_1, :numerical_units_1, :numerical_description_1, :numerical_size_2, :numerical_units_2, :numerical_description_2,
                  :area_1, :area_2, :area_units, :area_description, :range_1, :range_2, :range_units, :range_description, :unit_weight,
                  :category_id, :notes, :verified, :photo, :flagged)
          .merge(user: current_user)
  end

  def set_container_item
    @container_item = PackedItem.find(params[:id])
  end

  def set_container
    @container = Container.find(params[:container_id])
  end
end
