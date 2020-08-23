# frozen_string_literal: true

class PalletsController < ApplicationController
  before_action :set_pallet, only: %i[show destroy edit update]

  def new
    cid = Pallet.all.pluck(:custom_uid).max.to_i + 1
    name = "PALLET-#{cid}"
    @pallet = Pallet.new(custom_uid: cid, name: name, status: Pallet::STATUSES[0])
  end

  def create
    pallet = Pallet.create(pallet_params.merge(user: current_user))
    redirect_to pallet_path(pallet)
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
    params.require(:pallet).permit(:name, :status, :notes, :custom_uid, :container_id)
  end

  def set_pallet
    @pallet = Pallet.find(params[:id])
  end
end
