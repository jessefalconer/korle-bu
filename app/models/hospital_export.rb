# frozen_string_literal: true

class HospitalExport
  include ActiveModel::Model
  require "csv"

  attr_accessor :start_date, :end_date

  def initialize(id, options = {})
    options["start_date"] ||= Time.zone.today
    options["end_date"] ||= Time.zone.today
    @hospital = Hospital.find(id)
    @start_date = options["start_date"].to_datetime.beginning_of_day
    @end_date = options["end_date"].to_datetime.end_of_day
  end

  def to_csv
    collection = @hospital.unpacking_events.where(created_at: @start_date..@end_date).order(:created_at)

    CSV.generate(headers: true) do |csv|
      csv << %w[Item Category Quantity User]

      collection.each do |event|
        csv << [event.generated_name, event.category.name, event.quantity, event.user.name]
      end
    end
  end
end
