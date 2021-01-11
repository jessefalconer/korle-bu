# frozen_string_literal: true

class BoxesController < ApplicationController
  load_and_authorize_resource
  before_action :set_box, only: %i[show destroy update]

  def new
    cid = Box.all.pluck(:custom_uid).max.to_i + 1
    name = "BOX-#{cid}"
    @box = Box.new(custom_uid: cid, name: name, container_id: params[:container_id], pallet_id: params[:pallet_id])
  end

  def create
    box = Box.new(box_params.merge(user: current_user))

    if box.save
      redirect_to box_path(box), flash: { success: "Box creation successful." }
    else
      redirect_to boxes_path, flash: { error: "Failed to create new box: #{box.errors.full_messages.to_sentence}" }
    end
  end

  def index
    @boxes = if params[:display]
      Box.accessible_by(current_ability).send(params[:display]).order(:custom_uid).reverse_order.page params[:page]
    else
      Box.accessible_by(current_ability).order(:custom_uid).reverse_order.page params[:page]
    end
  end

  def show
  end

  def update
    if @box.update(box_params)
      redirect_to box_path(@box), flash: { success: "Box update successful." }
    else
      redirect_to box_path(@box), flash: { error: "Failed to update box: #{@box.errors.full_messages.to_sentence}" }
    end
  end

  def destroy
    @box.destroy
    redirect_to boxes_path, flash: { success: "Box deletion successful." }
  end

  private

  def box_params
    params.require(:box).permit(:name, :status, :notes, :custom_uid, :pallet_id, :container_id)
  end

  def set_box
    @box = Box.find(params[:id])
  end
end
