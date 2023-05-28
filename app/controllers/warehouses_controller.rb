# frozen_string_literal: true

class WarehousesController < ApplicationController
  load_and_authorize_resource
  before_action :set_warehouse, only: %i[show destroy update]

  def new
    @warehouse = Warehouse.new
  end

  def create
    warehouse = Warehouse.new(warehouse_params.merge(user: current_user))

    if warehouse.save
      redirect_to warehouse_path(warehouse),
                  flash: { success: "Warehouse created." }
    else
      redirect_to warehouses_path,
                  flash: { error: "Failed to create new warehouse: #{warehouse.errors.full_messages.to_sentence}" }
    end
  end

  def index
    @warehouses = Warehouse.all.order(:name).page params[:page]
  end

  def show
  end

  def update
    if @warehouse.update(warehouse_params)
      redirect_to warehouse_path(@warehouse),
                  flash: { success: "Warehouse updated." }
    else
      redirect_to warehouse_path(@warehouse),
                  flash: { error: "Failed to update warehouse: #{@warehouse.errors.full_messages.to_sentence}" }
    end
  end

  def destroy
    @warehouse.destroy
    redirect_to warehouses_path, flash: { success: "Warehouse deleted." }
  end

  private

  def warehouse_params
    params.require(:warehouse).permit(
      :name, :status, :notes, :user_id, :street, :city,
      :province, :postal_code, :country
    )
  end

  def set_warehouse
    @warehouse = Warehouse.find(params[:id])
  end
end
