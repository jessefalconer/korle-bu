# frozen_string_literal: true

class BoxItemsController < ApplicationController
  before_action :set_box
  before_action :set_box_item, except: %i[create index add_with_item mass_reassign]

  def create
    box_item = @box.box_items.build(box_item_params)

    if box_item.save
      id_sentence = box_item.show_id ? "ID: ##{box_item.id}." : ""
      message = { success: "#{box_item.quantity} #{box_item.generated_name.pluralize} added. #{id_sentence}" }
    else
      message = { error: box_item.errors.full_messages.to_sentence }
    end

    redirect_to box_box_items_path(@box), flash: message
  end

  def update
    if @box_item.update(box_item_params)
      id_sentence = @box_item.show_id ? "ID: ##{@box_item.id}." : ""
      message = { success: "#{@box_item.quantity} #{@box_item.generated_name.pluralize} updated. #{id_sentence}" }
    else
      message = { error: @box_item.errors.full_messages.to_sentence }
    end

    redirect_to box_box_items_path(@box), flash: message
  end

  def index
    @boxes = Box.reassignable.order(:id).reverse_order.pluck(:name, :id)
    @pallets = Pallet.reassignable.order(:id).reverse_order.pluck(:name, :id)
    @containers = Container.in_progress.order(:id).reverse_order.pluck(:name, :id)
  end

  def add_with_item
    item = Item.new(item_params)
    box_item = @box.box_items.build(box_item_params.merge(item: item))

    if item.save && box_item.save
      id_sentence = box_item.show_id ? "ID: ##{box_item.id}." : ""
      message = { success: "Item created. #{box_item.quantity} #{item.generated_name.pluralize} added. #{id_sentence}" }
    else
      error_message = item.errors.full_messages + box_item.errors.full_messages
      message = { error: error_message.to_sentence }
    end

    redirect_to box_box_items_path(@box), flash: message
  end

  def mass_reassign
    if params[:packed_item_ids].nil?
      redirect_to box_path(@box), flash: { error: "No items where selected." }
    else
      PackedItem.where(id: params[:packed_item_ids]).update(box_id: @box.id)
      redirect_to box_path(@box), flash: { success: "Items reassigned." }
    end
  end

  def destroy
    @box_item.destroy
    redirect_to box_box_items_path(@box)
  end

  private

  def box_item_params
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

  def set_box_item
    @box_item = PackedItem.find(params[:id])
  end

  def set_box
    @box = Box.find(params[:box_id])
  end
end
