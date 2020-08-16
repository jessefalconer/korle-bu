# frozen_string_literal: true

class WarehousesController < ApplicationController
  before_action :set_warehouse, only: %i[show destroy edit update]

  def new
    @warehouse = Warehouse.new
  end

  def create
    warehouse = Warehouse.create(warehouse_params.merge(user_id: current_user.id))
    redirect_to warehouse_path(warehouse)
  end

  def index
    @warehouses = Warehouse.all.page params[:page]
  end

  def show
  end

  def edit
  end

  def update
    @warehouse.update(warehouse_params)
    redirect_to warehouse_path(@warehouse)
  end

  def destroy
    @warehouse.destroy
    redirect_to warehouses_path
  end

  private

  def warehouse_params
    params.require(:warehouse).permit(:name, :status, :notes, :user_id, :street, :city, :province, :postal_code, :country)
  end

  def set_warehouse
    @warehouse = Warehouse.find(params[:id])
  end
end
