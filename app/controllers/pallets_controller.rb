# frozen_string_literal: true

class PalletsController < ApplicationController
  load_and_authorize_resource
  before_action :set_pallet, only: %i[show destroy update]

  def new
    @pallet = Pallet.new(container_id: params[:container_id])
  end

  def create
    pallet = Pallet.new(pallet_params.merge(user: current_user))

    if pallet.save
      redirect_to pallet_path(pallet), flash: { success: "Pallet created." }
    else
      redirect_to pallets_path,
        flash: { error: "Failed to create new pallet: #{pallet.errors.full_messages.to_sentence}" }
    end
  end

  def index
    @pallets = if params[:display]
      Pallet.includes(:boxes, shipment: :receiving_warehouse)
        .accessible_by(current_ability)
        .send(params[:display])
        .order(custom_uid: :desc)
        .page params[:page]
    else
      Pallet.includes(:boxes, shipment: :receiving_warehouse)
        .where.not(status: %w[Warehoused Staged])
        .accessible_by(current_ability)
        .order(custom_uid: :desc)
        .page params[:page]
    end

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

  def show
    @staged_items = PackedItem.staged
      .order(created_at: :desc)
    @staged_boxes = Box.staged
      .order(custom_uid: :desc)
    @warehoused_items = PackedItem.warehoused
      .order(created_at: :desc)
    @warehoused_boxes = Box.warehoused
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
    if @pallet.update(pallet_params)
      redirect_to pallet_path(@pallet), flash: { success: "Pallet updated." }
    else
      redirect_to pallet_path(@pallet),
        flash: { error: "Failed to update pallet: #{@pallet.errors.full_messages.to_sentence}" }
    end
  end

  def destroy
    @pallet.destroy
    redirect_to pallets_path, flash: { success: "Pallet deleted." }
  end

  def find
    pallet = Pallet.accessible_by(current_ability)
      .find_by(custom_uid: pallet_params[:custom_uid])

    if pallet
      path = params[:button] == "info" ? pallet_path(pallet) : pallet_pallet_items_path(pallet)
      redirect_to path
    else
      redirect_to params[:redirect],
      flash: { error: "Pallet with custom ID #{pallet_params[:custom_uid]} not found." }
    end
  end

  def unpack_all
    # Definitely move this to a service :/
    if params[:hospital_id].blank?
      message = { error: "Please select a hospital/facility/clinic." }
    else
      @pallet.pallet_items.each do |pi|
        next if pi.remaining_quantity.zero?

        pi.unpacking_events
          .create(
            hospital_id: params[:hospital_id],
            notes: params[:notes],
            user: current_user,
            timestamp: params[:timestamp],
            quantity: pi.remaining_quantity
          )
      end

      message = { success: "#{@pallet.pallet_items.count} item(s) unpacked." }
    end

    redirect_back fallback_location: request.referer, flash: message
  end

  private

  def pallet_params
    params.require(:pallet)
      .permit(
        :name, :status, :notes, :custom_uid,
        :container_id, :category_id, :weight
      )
  end

  def set_pallet
    @pallet = Pallet.includes(
      :pallet_items,
      boxes: [
        container: :shipment,
        box_items: :item,
        pallet: [container: :shipment]
      ]
    ).find(params[:id])
  end
end
