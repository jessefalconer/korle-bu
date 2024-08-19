# frozen_string_literal: true

class UnpackingEventsExportsController < ApplicationController
  before_action :set_export, only: :create

  def create
    start_date = export_params[:start_date].presence || UnpackingEvent.minimum(:created_at).strftime("%Y-%m-%d")
    end_date = export_params[:end_date].presence || DateTime.now.strftime("%Y-%m-%d")
    file_name = "Unpacking-Events-#{start_date}-to-#{end_date}"
    file_name += "-#{Hospital.find(export_params[:hospital_id]).name}" if export_params[:hospital_id].present?

    send_data(
      @export.to_csv,
      filename: file_name + ".csv"
    )
  end

  private

  def set_export
    @export = UnpackingEventsExport.new(
        export_params[:start_date],
        export_params[:end_date],
        export_params[:hospital_id],
        export_params[:sorting]
      )
  end

  def export_params
    params.require(:unpacking_events_export).permit(:start_date, :end_date, :hospital_id, :sorting)
  end
end
