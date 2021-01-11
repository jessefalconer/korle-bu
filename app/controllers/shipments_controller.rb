# frozen_string_literal: true

class ShipmentsController < ApplicationController
  load_and_authorize_resource
  before_action :set_shipment, only: %i[show destroy update]

  def new
    cid = Shipment.all.pluck(:custom_uid).max.to_i + 1
    name = "SHIPMENT-#{cid}"
    @shipment = Shipment.new(custom_uid: cid, name: name)
  end

  def create
    shipment = Shipment.new(shipment_params.merge(user: current_user))

    if shipment.save
      redirect_to shipment_path(shipment), flash: { success: "Shipment creation successful." }
    else
      redirect_to shipments_path, flash: { error: "Failed to create new shipment: #{shipment.errors.full_messages.to_sentence}" }
    end
  end

  def index
    @shipments = Shipment.all.order(:custom_uid).reverse_order.page params[:page]
  end

  def show
    respond_to do |format|
      format.html
      format.csv { send_data @shipment.to_csv, filename: "shipment-#{@shipment.id}-#{Date.today}.csv" }
    end
  end

  def update
    if @shipment.update(shipment_params)
      redirect_to shipment_path(@shipment), flash: { success: "Shipment update successful." }
    else
      redirect_to shipment_path(@shipment), flash: { error: "Failed to update shipment: #{@shipment.errors.full_messages.to_sentence}" }
    end
  end

  def destroy
    @shipment.destroy
    redirect_to shipments_path, flash: { success: "Shipment deletion successful." }
  end

  private

  def shipment_params
    params.require(:shipment).permit(:name, :status, :notes, :custom_uid, :receiving_warehouse_id, :shipping_warehouse_id)
  end

  def set_shipment
    @shipment = Shipment.find(params[:id])
  end
end
