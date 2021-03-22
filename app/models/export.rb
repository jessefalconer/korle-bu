# frozen_string_literal: true

class Export
  include ActiveModel::Model
  require "csv"

  attr_accessor :sort_by, :group_by

  def initialize(klass, id, options = {})
    @klass = klass.constantize
    # TODO, exports should be from any level
    # hence {@object} instead of {@shipment}
    @object = @klass.find(id.to_i)
    @group_by = options["group_by"]
    # @sort_by = options.dig("sort_by")
  end

  def to_csv
    CSV.generate(headers: true) do |csv|
      case @group_by
      when "category"
        csv << %w[Category Item Item\ Quantity Item\ Weight\ (kg) Locations]
        generate_by_category(@object.packed_items, csv)
      when "item"
        csv << %w[Item Item\ Quantity Category Item\ Weight\ (kg) Locations]
        generate_by_item(@object.packed_items, csv)
      else
        csv << ["Error generating CSV"]
      end
    end
  end

  def generate_by_category(collection, csv)
    collection.by_category.sort.each do |category, items|
      csv << [category, "-", "-", "-", "-"]
      items.sort.each do |item, values|
        csv << ["-", item, values[:quantity], values[:weight], values[:location]]
      end
    end
  end

  def generate_by_item(collection, csv)
    collection.by_item.sort.each do |item, values|
      csv << [item, values[:quantity], values[:category], values[:weight], values[:location]]
    end
  end
end
