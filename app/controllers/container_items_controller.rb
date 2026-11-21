# frozen_string_literal: true

class ContainerItemsController < ApplicationController
  include PlacementAuthorization

  before_action :set_container
  before_action :set_container_item, except: %i[create index add_with_item]

  def index
    authorize! :read, @container
    @box_options = Box.reassignable.order(id: :desc).pluck(:name, :id)
    @pallet_options = Pallet.reassignable.order(id: :desc).pluck(:name, :id)
    @container_options = Container.in_progress.order(id: :desc).pluck(:name, :id)
  end

  def create
    container_item = @container.container_items.build(container_item_params)
    authorize_placement!(:create, container_item)

    if container_item.save
      id_sentence = container_item.show_id ? "ID: ##{container_item.id}." : ""
      message = { success: "#{container_item.quantity} #{container_item.generated_name.pluralize} added. #{id_sentence}" }
    else
      message = { error: container_item.errors.full_messages.to_sentence }
    end

    redirect_to container_container_items_path(@container), flash: message
  end

  def update
    assign_with_placement!(@container_item, container_item_params)
    if @container_item.save
      id_sentence = @container_item.show_id ? "ID: ##{@container_item.id}." : ""
      message = { success: "#{@container_item.quantity} #{@container_item.generated_name.pluralize} updated. #{id_sentence}" }
    else
      message = { error: @container_item.errors.full_messages.to_sentence }
    end

    redirect_to container_container_items_path(@container), flash: message
  end

  def add_with_item
    item = Item.new(item_params)
    container_item = @container.container_items
      .build(container_item_params.merge(item: item))
    authorize! :create, item
    authorize_placement!(:create, container_item)

    if item.save && container_item.save
      id_sentence = container_item.show_id ? "ID: ##{container_item.id}." : ""
      message = { success: "Item created. #{container_item.quantity} #{item.generated_name.pluralize} added. #{id_sentence}" }
    else
      error_message = item.errors.full_messages + container_item.errors.full_messages
      message = { error: error_message.to_sentence }
    end

    redirect_to container_container_items_path(@container), flash: message
  end

  def destroy
    authorize_placement!(:destroy, @container_item)
    @container_item.destroy
    redirect_to container_container_items_path(@container)
  end

  private

  def container_item_params
    params
      .expect(
        packed_item: %i[expiry_date quantity item_id weight
                        box_id pallet_id container_id show_id status]
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

  def set_container_item
    @container_item = PackedItem.find(params.expect(:id))
  end

  def set_container
    @container = Container.find(params.expect(:container_id))
  end
end
