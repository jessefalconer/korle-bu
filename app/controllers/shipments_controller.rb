# frozen_string_literal: true

class ShipmentsController < ApplicationController
  load_and_authorize_resource
  before_action :set_shipment, only: %i[show destroy update]

  def new
    @shipment = Shipment.new
  end

  def create
    shipment = Shipment.new(shipment_params.merge(user: current_user))

    if shipment.save
      redirect_to shipment_path(shipment), flash: { success: "Shipment created." }
    else
      redirect_to shipments_path, flash: { error: "Failed to create new shipment: #{shipment.errors.full_messages.to_sentence}" }
    end
  end

  def index
    @shipments = Shipment.accessible_by(current_ability).order(:custom_uid).reverse_order.page params[:page]
  end

  def show
    respond_to do |format|
      format.html do
        @staged_items = PackedItem.staged
        @staged_boxes = Box.staged
        @staged_pallets = Pallet.staged
        @warehoused_items = PackedItem.warehoused
        @warehoused_boxes = Box.warehoused
        @warehoused_pallets = Pallet.warehoused
        @box_options = Box.reassignable.order(:id).reverse_order.pluck(:name, :id)
        @pallet_options = Pallet.reassignable.order(:id).reverse_order.pluck(:name, :id)
        @container_options = Container.order(:id).reverse_order.pluck(:name, :id)
      end
      format.csv { send_data @shipment.to_csv, filename: "shipment-#{@shipment.id}-#{Time.zone.today}.csv" }
    end
  end

  def update
    if @shipment.update(shipment_params)
      redirect_to shipment_path(@shipment), flash: { success: "Shipment updated." }
    else
      redirect_to shipment_path(@shipment), flash: { error: "Failed to update shipment: #{@shipment.errors.full_messages.to_sentence}" }
    end
  end

  def destroy
    @shipment.destroy
    redirect_to shipments_path, flash: { success: "Shipment deleted." }
  end

  private

  def shipment_params
    params.require(:shipment).permit(:name, :status, :notes, :custom_uid, :receiving_warehouse_id, :shipping_warehouse_id)
  end

  def set_shipment
    @shipment = Shipment.find(params[:id])
  end
end
