# frozen_string_literal: true

class UnpackingEventsExportsController < ApplicationController
  # Exports cover every warehouse, so only those who manage shipments (Admins) get them.
  before_action { authorize! :manage, Shipment }
  before_action :set_export, only: :create

  def create
    file_name = "Unpacking-Events-#{@export.start_date.iso8601}-to-#{@export.end_date.iso8601}"
    file_name += "-#{Hospital.find(export_params[:hospital_id]).name}" if export_params[:hospital_id].present?

    # The byte-order mark makes Excel read the file as UTF-8
    send_data(
      CsvSafety::BOM + @export.to_csv,
      type: "text/csv; charset=utf-8",
      filename: "#{file_name}.csv"
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
    params.expect(unpacking_events_export: %i[start_date end_date hospital_id sorting])
  end
end
