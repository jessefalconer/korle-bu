# frozen_string_literal: true

class UnpackingEventsExport
  include ActiveModel::Model
  require "csv"

  attr_accessor :group_by

  def initialize(start_date, end_date, hospital_id, sorting)
    @start_date = start_date.presence || UnpackingEvent.first.created_at.strftime("%Y-%m-%d")
    @end_date = end_date.presence || DateTime.now.strftime("%Y-%m-%d")
    @hospital_id = hospital_id
    @sorting = sorting
  end

  def to_csv
    CSV.generate(headers: true) do |csv|
      csv << %w[Item Item\ ID Quantity Origin Destination User Date]
      collection = UnpackingEvent.where(
        "created_at >= ? AND created_at <= ?", @start_date, @end_date
      )
      collection = collection.where(hospital_id: @hospital_id) if @hospital_id.present?

      generate_rows(collection, csv)
    end
  end

  def generate_rows(collection, csv)
    collection.order(created_at: @sorting.to_sym).each do |event|
      csv << [
        event.generated_name,
        event.packed_item.item_id,
        event.quantity,
        event.packed_item.location_name,
        event.hospital.name,
        event.user.name,
        event.created_at.strftime("%Y-%m-%d")
      ]
    end
  end
end
