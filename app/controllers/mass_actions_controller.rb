# frozen_string_literal: true

class MassActionsController < ApplicationController
  # TODO: sort out permissions, move to service class
  # load_and_authorize_resource
  before_action :redirect_if_invalid

  def mass_action
    PackedItem.where(id: params[:packed_item_ids]).update_all(build_params)
    if params[:box_id].blank?
      Box.where(id: params[:box_ids]).update_all(build_params.except(:box_id))
    end
    if params[:container_id].present?
      Pallet.where(id: params[:pallet_ids]).update_all(build_params.except(:box_id, :pallet_id))
    end

    redirect_to params[:redirect], flash: { success: "Records reassigned to #{@name}." }
  end

  private

  def build_params
    if params[:status].present?
      @name = params[:status]

      { box_id: nil, pallet_id: nil, container_id: nil, status: params[:status] }
    elsif params[:box_id].present?
      @box = Box.find(params[:box_id])
      @name = @box.name

      { box_id: params[:box_id], pallet_id: nil, container_id: nil, status: @box.status }
    elsif params[:pallet_id].present?
      @pallet = Pallet.find(params[:pallet_id])
      @name = @pallet.name

      { box_id: nil, pallet_id: params[:pallet_id], container_id: nil, status: @pallet.status }
    elsif params[:container_id].present?
      @container = Container.find(params[:container_id])
      @name = @container.name

      { box_id: nil, pallet_id: nil, container_id: params[:container_id], status: @container.status }
    end
  end

  def redirect_if_invalid
    unless params[:status].present? || params[:box_id].present? || params[:pallet_id].present? || params[:container_id].present?
      redirect_to params[:redirect], flash: { error: "No assignment destination selected." }
    end
  end
end
