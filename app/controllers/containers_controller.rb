# frozen_string_literal: true

class ContainersController < ApplicationController
  before_action :set_container, only: %i[show destroy edit update]

  def new
    cid = Container.all.pluck(:custom_uid).max.to_i + 1
    name = "CONTAINER-#{cid}"
    @container = Container.new(custom_uid: cid, name: name, status: Container::STATUSES[0])
  end

  def create
    container = Container.create(container_params.merge(user: current_user))
    redirect_to container_path(container)
  end

  def index
    @containers = Container.all.page params[:page]
  end

  def show
  end

  def edit
  end

  def update
    @container.update(container_params)
    redirect_to container_path(@container)
  end

  def destroy
    @container.destroy
    redirect_to containers_path
  end

  private

  def container_params
    params.require(:container).permit(:name, :status, :notes, :custom_uid, :shipment_id)
  end

  def set_container
    @container = Container.find(params[:id])
  end
end
