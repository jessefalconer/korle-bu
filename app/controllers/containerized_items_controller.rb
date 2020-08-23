# frozen_string_literal: true

class ContainerizedItemsController < ApplicationController
  before_action :set_container, only: %i[update create]

  def create
    @container.containerized_items.create(containerized_item_params.merge(user: current_user))
    redirect_to container_path(@container), flash: { success: "Saved!" }
  end

  def update
    @container.update(containerized_item_params)
    redirect_to container_path(@container), flash: { success: "Saved!" }
  end

  private

  def containerized_item_params
    params.require(:container).permit(:user, :item_id, :expiry_date, :quantity, boxed_items_attributes: %i[id item_id expiry_date quantity _destroy])
  end

  def set_container
    @container = Container.find(params[:container_id])
  end
end
