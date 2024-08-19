# frozen_string_literal: true

class ContainersController < ApplicationController
  load_and_authorize_resource
  before_action :set_container, only: %i[show destroy update]

  def new
    @container = Container.new(shipment_id: params[:shipment_id])
  end

  def create
    container = Container.new(container_params.merge(user: current_user))

    if container.save
      redirect_to container_path(container), flash: { success: "Container created." }
    else
      redirect_to containers_path,
        flash: { error: "Failed to create new container: #{container.errors.full_messages.to_sentence}" }
    end
  end

  def index
    @containers = if params[:display]
      Container.includes(shipment: :receiving_warehouse)
        .accessible_by(current_ability)
        .send(params[:display])
        .order(custom_uid: :desc)
        .page params[:page]
    else
      Container.includes(shipment: :receiving_warehouse)
        .accessible_by(current_ability)
        .order(custom_uid: :desc)
        .page params[:page]
    end
  end

  def show
    @staged_items = PackedItem.staged
      .order(created_at: :desc)
    @staged_boxes = Box.staged
      .order(custom_uid: :desc)
    @staged_pallets = Pallet.staged
      .order(custom_uid: :desc)
    @warehoused_items = PackedItem.warehoused
      .order(created_at: :desc)
    @warehoused_boxes = Box.warehoused
      .order(custom_uid: :desc)
    @warehoused_pallets = Pallet.warehoused
      .order(custom_uid: :desc)
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

  def update
    if @container.update(container_params)
      redirect_to container_path(@container),
        flash: { success: "Container updated." }
    else
      redirect_to container_path(@container),
        flash: { error: "Failed to update container: #{@container.errors.full_messages.to_sentence}" }
    end
  end

  def destroy
    @container.destroy
    redirect_to containers_path, flash: { success: "Container deleted." }
  end

  private

  def container_params
    params.require(:container)
      .permit(:name, :status, :notes, :custom_uid, :shipment_id, :weight)
  end

  def set_container
    @container = Container.includes(
      :boxes, :pallets, :shipment, container_items: :item
    ).find(params[:id])
  end
end
