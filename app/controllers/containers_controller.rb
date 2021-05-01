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
      redirect_to containers_path, flash: { error: "Failed to create new container: #{container.errors.full_messages.to_sentence}" }
    end
  end

  def index
    @containers = if params[:display]
      Container.accessible_by(current_ability).send(params[:display]).order(:custom_uid).reverse_order.page params[:page]
    else
      Container.accessible_by(current_ability).order(:custom_uid).reverse_order.page params[:page]
    end
  end

  def show
  end

  def update
    if @container.update(container_params)
      redirect_to container_path(@container), flash: { success: "Container updated." }
    else
      redirect_to container_path(@container), flash: { error: "Failed to update container: #{@container.errors.full_messages.to_sentence}" }
    end
  end

  def destroy
    @container.destroy
    redirect_to containers_path, flash: { success: "Container deleted." }
  end

  private

  def container_params
    params.require(:container).permit(:name, :status, :notes, :custom_uid, :shipment_id, :weight)
  end

  def set_container
    @container = Container.find(params[:id])
  end
end
