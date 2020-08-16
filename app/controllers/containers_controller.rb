# frozen_string_literal: true

class ContainersController < ApplicationController
  before_action :set_container, only: %i[show destroy edit update]
  before_action :set_shipment, except: %i[list]

  def list
    @containers = Container.all.page params[:page]
  end

  def new
    @container = Container.new
  end

  def create
    @shipment.containers.create(container_params.merge(user: current_user))
    redirect_to shipment_containers_path
  end

  def index
    @containers = @shipment.containers.page params[:page]
  end

  def show
  end

  def edit
  end

  def update
    @container.update(container_params)
    redirect_to shipment_container_path(@container)
  end

  def destroy
    @container.destroy
    redirect_to shipment_containers_path
  end

  private

  def container_params
    params.require(:container).permit(:name, :status, :notes)
  end

  def set_container
    @container = Container.find(params[:id])
  end

  def set_shipment
    @shipment = Shipment.find(params[:shipment_id])
  end
end
