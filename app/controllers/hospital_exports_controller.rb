# frozen_string_literal: true

class HospitalExportsController < ApplicationController
  # Exports cover every warehouse, so only those who manage shipments (Admins) get them.
  before_action { authorize! :manage, Shipment }
  before_action :set_export, only: :create

  def create
    send_data(
      @export.to_csv,
      filename: "Hospital--#{Hospital.find(export_params[:id]).name}--#{Time.zone.today}.csv"
    )
  end

  private

  def set_export
    @export = HospitalExport.new(export_params[:id], export_params)
  end

  def export_params
    params.expect(hospital_export: %i[id start_date end_date])
  end
end
