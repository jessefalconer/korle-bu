# frozen_string_literal: true

class PalletsController < ApplicationController
  before_action :set_pallet, only: %i[show destroy edit update]
  before_action :set_variables, except: %i[list]

  def list
    @pallets = Pallet.all.page params[:page]
  end

  def new
    @pallet = Pallet.new
  end

  def create
    @container.pallets.create(pallet_params.merge(user: current_user))
    redirect_to shipment_container_pallets_path(@shipment, @container)
  end

  def index
    @pallets = @container.pallets.page params[:page]
  end

  def show
  end

  def edit
  end

  def update
    @pallet.update(pallet_params)
    redirect_to shipment_container_pallet_path(@shipment, @container)
  end

  def destroy
    @pallet.destroy
    redirect_to shipment_containers_path
  end

  private

  def pallet_params
    params.require(:pallet).permit(:name, :status, :notes, :container_id)
  end

  def set_pallet
    @pallet = Pallet.find(params[:id])
  end

  def set_variables
    @container = Container.find(params[:container_id])
    @shipment = @container.shipment || Shipment.find(params[:shipment_id])
  end
end
