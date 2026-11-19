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
      redirect_to shipment_path(shipment),
        flash: { success: "Shipment created." }
    else
      redirect_to shipments_path,
        flash: { error: "Failed to create new shipment: #{shipment.errors.full_messages.to_sentence}" }
    end
  end

  def index
    @shipments = Shipment.includes(:receiving_warehouse)
      .accessible_by(current_ability)
      .order(custom_uid: :desc)
      .page params[:page]
  end

  def show
    respond_to do |format|
      format.html do
        @staged_items = PackedItem.staged.preload(:item)
        @staged_boxes = Box.staged.with_location
        @staged_pallets = Pallet.staged.with_location
        @warehoused_items = PackedItem.warehoused.preload(:item)
        @warehoused_boxes = Box.warehoused.with_location
        @warehoused_pallets = Pallet.warehoused.with_location
        @box_options = Box.reassignable
          .order(id: :desc)
          .pluck(:name, :id)
        @pallet_options = Pallet.reassignable
          .order(id: :desc)
          .pluck(:name, :id)
        @container_options = Container.order(id: :desc)
          .pluck(:name, :id)
      end
      format.csv {
        send_data(
          @shipment.to_csv,
          filename: "shipment-#{@shipment.id}-#{Time.zone.today}.csv"
        )
      }
    end
  end

  def update
    if @shipment.update(shipment_params)
      redirect_to shipment_path(@shipment),
        flash: { success: "Shipment updated." }
    else
      redirect_to shipment_path(@shipment),
        flash: { error: "Failed to update shipment: #{@shipment.errors.full_messages.to_sentence}" }
    end
  end

  def destroy
    @shipment.destroy
    redirect_to shipments_path, flash: { success: "Shipment deleted." }
  end

  private

  def shipment_params
    params.require(:shipment)
      .permit(
        :name, :status, :notes, :custom_uid,
        :receiving_warehouse_id, :shipping_warehouse_id
      )
  end

  def set_shipment
    # Preload exactly the associations the show page renders, so their any?/size/each
    # calls don't each go back to the database.
    @shipment = Shipment.preload(
        :containers, :receiving_warehouse, :shipping_warehouse, :user,
        :pallets, :pallet_boxes, :container_boxes,
        container_items: :item, pallet_items: :item, box_items: :item
      ).find(params[:id])
  end
end
