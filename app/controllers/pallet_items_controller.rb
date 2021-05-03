# frozen_string_literal: true

class PalletItemsController < ApplicationController
  before_action :set_pallet
  before_action :set_pallet_item, except: %i[create index add_with_item mass_reassign]

  def create
    pallet_item = @pallet.pallet_items.build(pallet_item_params)

    if pallet_item.save
      id_sentence = pallet_item.show_id ? "ID: ##{pallet_item.id}." : ""
      message = { success: "#{pallet_item.quantity} #{pallet_item.generated_name.pluralize} added. #{id_sentence}" }
    else
      message = { error: pallet_item.errors.full_messages.to_sentence }
    end

    redirect_to pallet_pallet_items_path(@pallet), flash: message
  end

  def update
    if @pallet_item.update(pallet_item_params)
      id_sentence = @pallet_item.show_id ? "ID: ##{@pallet_item.id}." : ""
      message = { success: "#{@pallet_item.quantity} #{@pallet_item.generated_name.pluralize} updated. #{id_sentence}" }
    else
      message = { error: @pallet_item.errors.full_messages.to_sentence }
    end

    redirect_to pallet_pallet_items_path(@pallet), flash: message
  end

  def index
    @boxes = Box.in_progress.order(:id).reverse_order
    @pallets = Pallet.in_progress.order(:id).reverse_order
    @containers = Container.in_progress.order(:id).reverse_order
  end

  def add_with_item
    item = Item.new(item_params)
    pallet_item = @pallet.pallet_items.build(pallet_item_params.merge(item: item))

    if item.save && pallet_item.save
      id_sentence = pallet_item.show_id ? "ID: ##{pallet_item.id}." : ""
      message = { success: "Item created. #{pallet_item.quantity} #{item.generated_name.pluralize} added. #{id_sentence}" }
    else
      error_message = item.errors.full_messages + pallet_item.errors.full_messages
      message = { error: error_message.to_sentence }
    end

    redirect_to pallet_pallet_items_path(@pallet), flash: message
  end

  def mass_reassign
    if params[:packed_item_ids].nil?
      redirect_to pallet_path(@pallet), flash: { error: "No items where selected." }
    else
      PackedItem.where(id: params[:packed_item_ids]).update_all(pallet_id: @pallet.id)
      redirect_to pallet_path(@pallet), flash: { success: "Items reassigned." }
    end
  end

  def destroy
    @pallet_item.destroy
    redirect_to pallet_pallet_items_path(@pallet)
  end

  private

  # TODO: params not submitting
  def pallet_item_params
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

  def set_pallet_item
    @pallet_item = PackedItem.find(params[:id])
  end

  def set_pallet
    @pallet = Pallet.find(params[:pallet_id])
  end
end
