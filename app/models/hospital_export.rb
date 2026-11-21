# frozen_string_literal: true

class HospitalExport
  include ActiveModel::Model

  require "csv"

  attr_accessor :start_date, :end_date

  def initialize(id, options = {})
    @hospital = Hospital.find(id)
    # Blank or missing dates (a cleared date field) mean today.
    @start_date = (options["start_date"].presence&.to_date || Time.zone.today).in_time_zone.beginning_of_day
    @end_date = (options["end_date"].presence&.to_date || Time.zone.today).in_time_zone.end_of_day
  end

  def to_csv
    collection = @hospital.unpacking_events
      .where(created_at: @start_date..@end_date)
      .order(:created_at)

    CSV.generate(headers: true) do |csv|
      csv << %w[Item Category Quantity User Date]

      collection.each do |event|
        csv << [
          event.generated_name, event.category&.name || "N/A", event.quantity,
          event.user.name, event.created_at.strftime("%Y-%m-%d")
        ]
      end
    end
  end
end
