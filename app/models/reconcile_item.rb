# frozen_string_literal: true

class ReconcileItem
  def initialize(current_user, _item = nil)
    @current_user = current_user
  end

  # Possibly move these to Item
  def find_similar_records(item)
    Item.search_by_generated_name(item.generated_name).where.not(id: item.id)
  end

  def execute_merge(item, target_item, delete: false, verify: true)
    PackedItem.where(item_id: item.id).update_all(item_id: target_item.id) # rubocop:disable Rails/SkipsModelValidations#

    Item.find(item.id).destroy if delete
    Item.find(target_item.id).update(verified: verify) if verify
  end
end
