# frozen_string_literal: true

class ShipmentExportsController < ApplicationController
  # Exports cover every warehouse, so only those who manage shipments (Admins) get them.
  before_action { authorize! :manage, Shipment }
  before_action :set_export, only: :create

  def create
    send_data(
      @export.to_csv,
      filename: "Shipment--#{export_params[:id]}-#{Time.zone.today}.csv"
    )
  end

  private

  def set_export
    @export = ShipmentExport.new(export_params[:id], export_params[:group_by])
  end

  def export_params
    params.expect(shipment_export: %i[id group_by])
  end
end
