# frozen_string_literal: true

class MassActionsController < ApplicationController
  # TODO: sort out permissions
  # load_and_authorize_resource

  def mass_action
    if params[:status].present?
      PackedItem.where(id: params[:packed_item_ids])
        .update_all(box_id: nil, pallet_id: nil, container_id: nil, status: params[:status])
      message = { success: "Items moved to #{params[:status]}."}
    else
      PackedItem.where(id: params[:packed_item_ids])
                .update_all(box_id: params[:box_id], pallet_id: params[:pallet_id], container_id: params[:container_id], status: PackedItem::PACKED)
      message = { success: "Items reassigned."}
    end

    redirect_to params[:redirect], flash: message
  end
end
