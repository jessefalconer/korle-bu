# frozen_string_literal: true

class HospitalExportsController < ApplicationController
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
    params.require(:hospital_export).permit(:id, :start_date, :end_date)
  end
end
