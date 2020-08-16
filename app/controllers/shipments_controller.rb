# frozen_string_literal: true

class ShipmentsController < ApplicationController
  before_action :set_shipment, only: %i[show destroy edit update]

  def new
    @shipment = Shipment.new(custom_uid: Shipment.count + 1)
  end

  def create
    Shipment.create(shipment_params.merge(user: current_user))
    redirect_to shipments_path
  end

  def index
    @shipments = Shipment.all.page params[:page]
  end

  def show
  end

  def edit
  end

  def update
    @shipment.update(shipment_params)
    redirect_to shipment_path(@shipment)
  end

  def destroy
    @shipment.destroy
    redirect_to shipments_path
  end

  private

  def shipment_params
    params.require(:shipment).permit(:name, :status, :notes, :receiving_warehouse_id, :shipping_warehouse_id, :custom_uid)
  end

  def set_shipment
    @shipment = Shipment.find(params[:id])
  end
end
