# frozen_string_literal: true

class PalletsController < ApplicationController
  load_and_authorize_resource
  before_action :set_pallet, only: %i[show destroy update]

  def new
    cid = Pallet.maximum(:custom_uid).to_i + 1
    name = "PALLET-#{cid}"
    @pallet = Pallet.new(custom_uid: cid, name: name, container_id: params[:container_id])
  end

  def create
    pallet = Pallet.new(pallet_params.merge(user: current_user))

    if pallet.save
      redirect_to pallet_path(pallet), flash: { success: "Pallet creation successful." }
    else
      redirect_to pallets_path, flash: { error: "Failed to create new pallet: #{pallet.errors.full_messages.to_sentence}" }
    end
  end

  def index
    @pallets = if params[:display]
      Pallet.accessible_by(current_ability).send(params[:display]).order(:custom_uid).reverse_order.page params[:page]
    else
      Pallet.accessible_by(current_ability).order(:custom_uid).reverse_order.page params[:page]
    end
  end

  def show
  end

  def update
    if @pallet.update(pallet_params)
      redirect_to pallet_path(@pallet), flash: { success: "Pallet update successful." }
    else
      redirect_to pallet_path(@pallet), flash: { error: "Failed to update pallet: #{@pallet.errors.full_messages.to_sentence}" }
    end
  end

  def destroy
    @pallet.destroy
    redirect_to pallets_path, flash: { success: "Pallet deletion successful." }
  end

  private

  def pallet_params
    params.require(:pallet).permit(:name, :status, :notes, :custom_uid, :container_id)
  end

  def set_pallet
    @pallet = Pallet.find(params[:id])
  end
end
