# frozen_string_literal: true

class WarehousedItemsController < ApplicationController
  before_action :set_packed_item, except: %i[create index add_with_item]

  def create
    packed_item = PackedItem.new(packed_item_params)

    if packed_item.save
      id_sentence = packed_item.show_id ? "ID: ##{packed_item.id}." : ""
      message = { success: "#{packed_item.quantity} #{packed_item.generated_name.pluralize} added. #{id_sentence}" }
    else
      message = { error: packed_item.errors.full_messages.to_sentence }
    end

    redirect_to warehoused_items_path, flash: message
  end

  def update
    if @packed_item.update(packed_item_params)
      id_sentence = @packed_item.show_id ? "ID: ##{@packed_item.id}." : ""
      message = { success: "#{@packed_item.quantity} #{@packed_item.generated_name.pluralize} updated. #{id_sentence}" }
    else
      message = { error: @packed_item.errors.full_messages.to_sentence }
    end

    redirect_to warehoused_items_path, flash: message
  end

  def index
    @packed_items = PackedItem.warehoused
      .order(:created_at)
      .reverse_order
      .page params[:page]
    @box_options = Box.reassignable
      .order(:id)
      .reverse_order
      .pluck(:name, :id)
    @pallet_options = Pallet.reassignable
      .order(:id)
      .reverse_order
      .pluck(:name, :id)
    @container_options = Container.in_progress
      .order(:id)
      .reverse_order
      .pluck(:name, :id)
  end

  def add_with_item
    item = Item.new(item_params)
    packed_item = item.packed_items
      .build(packed_item_params.merge(status: PackedItem::WAREHOUSE))

    if item.save && packed_item.save
      id_sentence = packed_item.show_id ? "ID: ##{packed_item.id}." : ""
      message = { success: "Item created. #{packed_item.quantity} #{item.generated_name.pluralize} added. #{id_sentence}" }
    else
      error_message = item.errors.full_messages + packed_item.errors.full_messages
      message = { error: error_message.to_sentence }
    end

    redirect_to warehoused_items_path, flash: message
  end

  def destroy
    @packed_item.destroy
    redirect_to warehoused_items_path
  end

  private

  def packed_item_params
    params.require(:packed_item)
      .permit(
        :expiry_date, :quantity, :item_id, :weight,
        :box_id, :pallet_id, :container_id, :show_id, :status
      )
      .merge(user: current_user)
  end

  def item_params
    params.require(:item)
      .permit(
        :brand, :object, :standardized_size,
        :numerical_size_1, :numerical_units_1, :numerical_description_1,
        :numerical_size_2, :numerical_units_2, :numerical_description_2,
        :area_1, :area_2, :area_units, :area_description,
        :range_1, :range_2, :range_units, :range_description, :unit_weight,
        :category_id, :notes, :verified, :photo, :flagged)
      .merge(user: current_user)
  end

  def set_packed_item
    @packed_item = PackedItem.find(params[:id])
  end
end
