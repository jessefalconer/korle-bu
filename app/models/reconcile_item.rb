# frozen_string_literal: true

class ReconcileItem
  def initialize(current_user, item = nil)
    @current_user = current_user
  end

  def unverified_items
    Item.where(verified: false)
  end

  def item_instances(item)
    count = 0
    count += ContainerizedItem.where(item_id: item.id).count
    count += PalletizedItem.where(item_id: item.id).count
    count += BoxedItem.where(item_id: item.id).count

    count
  end

  def find_similar_records(item)
    arr = item.generated_name.gsub(/\s+/m, ' ').strip.split(" ")

    results = arr.each_with_object({}) do |word, hash|
      hash[word] = Item.search_by_generated_name(word).where.not(id: item.id, verified: false).ids
    end

    results = results.values.flatten.inject(Hash.new(0)) { |h, e| h[e] += 1 ; h }

    results.sort_by {|k, v| v}.reverse!
  end

  def execute_merge(item, target_item, delete: false)
    BoxedItem.where(item_id: item.id).update_all(item_id: target_item.id)
    PalletizedItem.where(item_id: item.id).update_all(item_id: target_item.id)
    ContainerizedItem.where(item_id: item.id).update_all(item_id: target_item.id)

    Item.find(item.id).destroy if delete
  end

  def match_percentage(integer, item)
    size = item.generated_name.gsub(/\s+/m, ' ').strip.split(" ").size
    "#{(integer.to_f / size * 100).round(2)}%"
  end
end
