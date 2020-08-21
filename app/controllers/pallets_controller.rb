# frozen_string_literal: true

class PalletsController < ApplicationController
  before_action :set_pallet, only: %i[show destroy edit update]

  def list
    @pallets = Pallet.all.page params[:page]
  end

  def new
    @pallet = Pallet.new
  end

  def create
    Pallet.create(pallet_params.merge(user: current_user))
    redirect_to pallets_path
  end

  def index
    @pallets = Pallet.all.page params[:page]
  end

  def show
  end

  def edit
  end

  def update
    @pallet.update(pallet_params)
    redirect_to pallet_path(@pallet)
  end

  def destroy
    @pallet.destroy
    redirect_to pallets_path
  end

  private

  def pallet_params
    params.require(:pallet).permit(:name, :status, :notes, :container_id)
  end

  def set_pallet
    @pallet = Pallet.find(params[:id])
  end
end
