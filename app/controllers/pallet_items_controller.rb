# frozen_string_literal: true

class PalletItemsController < ApplicationController
  include PlacementAuthorization

  before_action :set_pallet
  before_action :set_pallet_item, except: %i[create index add_with_item]

  def index
    authorize! :read, @pallet
    @box_options = Box.reassignable
      .order(id: :desc)
      .pluck(:name, :id)
    @pallet_options = Pallet.reassignable
      .order(id: :desc)
      .pluck(:name, :id)
    @container_options = Container.in_progress
      .order(id: :desc)
      .pluck(:name, :id)
  end

  def create
    pallet_item = @pallet.pallet_items.build(pallet_item_params)
    authorize_placement!(:create, pallet_item)

    if pallet_item.save
      id_sentence = pallet_item.show_id ? "ID: ##{pallet_item.id}." : ""
      message = { success: "#{pallet_item.quantity} #{pallet_item.generated_name.pluralize} added. #{id_sentence}" }
    else
      message = { error: pallet_item.errors.full_messages.to_sentence }
    end

    redirect_to pallet_pallet_items_path(@pallet), flash: message
  end

  def update
    assign_with_placement!(@pallet_item, pallet_item_params)
    if @pallet_item.save
      id_sentence = @pallet_item.show_id ? "ID: ##{@pallet_item.id}." : ""
      message = { success: "#{@pallet_item.quantity} #{@pallet_item.generated_name.pluralize} updated. #{id_sentence}" }
    else
      message = { error: @pallet_item.errors.full_messages.to_sentence }
    end

    redirect_to pallet_pallet_items_path(@pallet), flash: message
  end

  def add_with_item
    item = Item.new(item_params)
    pallet_item = @pallet.pallet_items.build(pallet_item_params.merge(item: item))
    authorize! :create, item
    authorize_placement!(:create, pallet_item)

    if item.save && pallet_item.save
      id_sentence = pallet_item.show_id ? "ID: ##{pallet_item.id}." : ""
      message = { success: "Item created. #{pallet_item.quantity} #{item.generated_name.pluralize} added. #{id_sentence}" }
    else
      error_message = item.errors.full_messages + pallet_item.errors.full_messages
      message = { error: error_message.to_sentence }
    end

    redirect_to pallet_pallet_items_path(@pallet), flash: message
  end

  def destroy
    authorize_placement!(:destroy, @pallet_item)
    @pallet_item.destroy
    redirect_to pallet_pallet_items_path(@pallet)
  end

  private

  # TODO: params not submitting
  def pallet_item_params
    params
      .expect(
        packed_item: %i[expiry_date quantity item_id weight box_id
                        pallet_id container_id show_id status]
      )
      .merge(user: current_user)
  end

  def item_params
    params
      .expect(
        item: %i[brand serial_number object standardized_size
                 numerical_size_1 numerical_units_1 numerical_description_1
                 numerical_size_2 numerical_units_2 numerical_description_2
                 area_1 area_2 area_units area_description
                 range_1 range_2 range_units range_description unit_weight
                 category_id notes verified flagged]
      )
      .merge(user: current_user)
  end

  def set_pallet_item
    @pallet_item = PackedItem.find(params.expect(:id))
  end

  def set_pallet
    @pallet = Pallet.find(params.expect(:pallet_id))
  end
end
