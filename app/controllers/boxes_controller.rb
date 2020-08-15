# frozen_string_literal: true

class BoxesController < ApplicationController
  before_action :set_box, only: %i[show destroy edit update]
  before_action :set_variables, except: %i[list]

  def new
    @box = Box.new
  end

  def create
    @pallet.boxes.create(box_params.merge(user: current_user))
    redirect_to shipment_container_pallet_boxes_path(@shipment, @container, @pallet)
  end

  def index
    @boxes = @pallet.boxes
  end

  def list
    @boxes = Box.all
  end

  def show
  end

  def edit
  end

  def update
    @box.update(box_params)
    redirect_to shipment_container_pallet_box_path(@shipment, @container, @pallet)
  end

  def destroy
    @box.destroy
    redirect_to shipment_containers_path
  end

  private

  def box_params
    params.require(:box).permit(:name, :status, :notes)
  end

  def set_box
    @box = Box.find(params[:id])
  end

  def set_variables
    @pallet = Pallet.find(params[:pallet_id])
    @container = @pallet.container || Container.find(params[:container_id])
    @shipment = @container.shipment || Shipment.find(params[:shipment_id])
  end

  def set_container
    @container = Container.find(params[:container_id])
  end

  def set_shipment
    @shipment = Shipment.find(params[:shipment_id])
  end
end
