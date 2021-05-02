# frozen_string_literal: true

class BoxesController < ApplicationController
  load_and_authorize_resource
  before_action :set_box, only: %i[show destroy update]

  def new
    @box = Box.new(container_id: params[:container_id], pallet_id: params[:pallet_id])
  end

  def create
    box = Box.new(box_params.merge(user: current_user))

    if box.save
      redirect_to box_path(box), flash: { success: "Box created." }
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
    @staged_items = PackedItem.staged
  end

  def update
    if @box.update(box_params)
      redirect_to box_path(@box), flash: { success: "Box updated." }
    else
      redirect_to box_path(@box), flash: { error: "Failed to update box: #{@box.errors.full_messages.to_sentence}" }
    end
  end

  def destroy
    @box.destroy
    redirect_to boxes_path, flash: { success: "Box deleted." }
  end

  def find
    box = Box.accessible_by(current_ability).find_by(custom_uid: box_params[:custom_uid])
    if box
      redirect_to box_path(box)
    else
      redirect_to boxes_path, flash: { error: "Box with custom ID #{box_params[:custom_uid]} not found." }
    end
  end

  private

  def box_params
    params.require(:box).permit(:name, :status, :notes, :custom_uid, :pallet_id, :container_id, :weight)
  end

  def set_box
    @box = Box.find(params[:id])
  end
end
