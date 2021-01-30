# frozen_string_literal: true

class ReconcileItem
  def initialize(current_user, _item = nil)
    @current_user = current_user
  end

  def find_similar_records(item)
    arr = item.generated_name.split(/[\s-]+/)

    results = arr.index_with do |word|
      Item.search_by_generated_name(word).where.not(id: item.id).ids
    end

    results = results.values.flatten.each_with_object(Hash.new(0)) { |e, h| h[e] += 1; }

    results.sort_by { |_k, v| v }.reverse!
  end

  def execute_merge(item, target_item, delete: false, verify: true)
    PackedItem.where(item_id: item.id).update_all(item_id: target_item.id) # rubocop:disable Rails/SkipsModelValidations#

    Item.find(item.id).destroy if delete
    Item.find(target_item.id).update(verified: verify) if verify
  end

  # TODO: Move this to a presenter
  def match_percentage(integer, item)
    size = item.generated_name.split(/[\s-]+/).size
    "#{(integer.to_f / size * 100).round(2)}%"
  end
end
