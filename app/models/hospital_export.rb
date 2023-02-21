# frozen_string_literal: true

class HospitalExport
  include ActiveModel::Model
  require "csv"

  attr_accessor :start_date, :end_date

  def initialize(id, options = {})
    options["start_date"] ||= Date.today
    options["end_date"] ||= Date.today
    @hospital = Hospital.find(id)
    @start_date = options["start_date"].to_datetime.beginning_of_day
    @end_date = options["end_date"].to_datetime.end_of_day
  end

  def to_csv
    collection = @hospital.unpacking_events.where(created_at: @start_date..@end_date).order(:created_at)

    CSV.generate(headers: true) do |csv|
      csv << %w[Item Category Quantity]

      collection.each do |event|
        csv << [event.item, event.item.category, event.quantity]
      end
    end
  end
end
