# frozen_string_literal: true

class ExportsController < ApplicationController
  before_action :set_export, only: :create

  def create
    send_data @export.to_csv, filename: "#{export_params[:klass]}-#{export_params[:id]}-#{Time.zone.today}.csv"
  end

  private

  def set_export
    @export = Export.new(export_params[:klass], export_params[:id], export_params)
  end

  def export_params
    params.require(:export).permit(:id, :klass, :group_by, :sort_by)
  end
end
