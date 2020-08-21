# frozen_string_literal: true

class BoxesController < ApplicationController
  before_action :set_box, only: %i[show destroy edit update]

  def new
    @box = Box.new
  end

  def create
    Box.create(box_params.merge(user: current_user))
    redirect_to boxes_path
  end

  def index
    @boxes = Box.all.page params[:page]
  end

  def show
  end

  def edit
  end

  def update
    @box.update(box_params)
    redirect_to box_path(@box)
  end

  def destroy
    @box.destroy
    redirect_to boxes_path
  end

  private

  def box_params
    params.require(:box).permit(:name, :status, :notes)
  end

  def set_box
    @box = Box.find(params[:id])
  end
end
