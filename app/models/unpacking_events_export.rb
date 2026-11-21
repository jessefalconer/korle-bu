# frozen_string_literal: true

class UnpackingEventsExport
  include ActiveModel::Model

  require "csv"

  attr_accessor :group_by
  attr_reader :start_date, :end_date

  SORTINGS = %w[asc desc].freeze

  # Dates are whole days: a blank start means the first event ever, a blank
  # end means today. Both ends are inclusive.
  def initialize(start_date, end_date, hospital_id, sorting)
    @start_date = parse_date(start_date) || UnpackingEvent.minimum(:timestamp)&.to_date || Time.zone.today
    @end_date = parse_date(end_date) || Time.zone.today
    @hospital_id = hospital_id
    @sorting = SORTINGS.include?(sorting) ? sorting : "desc"
  end

  def to_csv
    CSV.generate(headers: true) do |csv|
      csv << ["Item", "Item ID", "Quantity", "Origin", "Destination", "User", "Date"]
      range = @start_date.in_time_zone.beginning_of_day..@end_date.in_time_zone.end_of_day
      collection = UnpackingEvent.where(timestamp: range)
      collection = collection.where(hospital_id: @hospital_id) if @hospital_id.present?

      generate_rows(collection, csv)
    end
  end

  def generate_rows(collection, csv)
    # Sorted by the date shown in the Date column.
    collection.order(timestamp: @sorting, id: @sorting).each do |event|
      csv << CsvSafety.row([
                             event.generated_name,
                             event.packed_item.item_id,
                             event.quantity,
                             event.packed_item.location_name,
                             event.hospital.name,
                             event.user.name,
                             event.timestamp.strftime("%Y-%m-%d")
                           ])
    end
  end

  private

  def parse_date(value)
    value.presence&.to_date
  rescue Date::Error
    nil
  end
end
