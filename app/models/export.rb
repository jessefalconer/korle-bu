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
    @group_by = options.dig("group_by")
    # @sort_by = options.dig("sort_by")
  end

  def to_csv
    CSV.generate(headers: true) do |csv|
      if @group_by == "category"
        csv << %w[category item item\ quantity]
        csv << ["Items in Container"]
        generate_by_category(@object.containerized_items, csv)
        csv << ["Items on Pallet"]
        generate_by_category(@object.palletized_items, csv)
        csv << ["Items in Boxes"]
        generate_by_category(@object.boxed_items, csv)
      elsif @group_by == "item"
        csv << %w[item item\ quantity category]
        csv << ["Items in Container"]
        generate_by_item(@object.containerized_items, csv)
        csv << ["Items on Pallet"]
        generate_by_item(@object.palletized_items, csv)
        csv << ["Items in Boxes"]
        generate_by_item(@object.boxed_items, csv)
      else
        csv << ["Error generating CSV"]
      end
    end
  end

  def generate_by_category(collection, csv)
    collection.by_category.sort.each do |category, items|
      csv << [category, "-", "-"]
      items.sort.each do |item|
        csv << ["-", item[0], item[1]]
      end
    end
  end

  def generate_by_item(collection, csv)
    collection.by_item.sort.each do |item, values|
      csv << [item, values[:quantity], values[:category]]
    end
  end
end
