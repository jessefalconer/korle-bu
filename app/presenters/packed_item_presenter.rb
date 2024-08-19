# frozen_string_literal: true

class PackedItemPresenter < BasePresenter
  def path
    if model.box_id
      box_box_items_path(model.box_id)
    elsif model.pallet_id
      pallet_pallet_items_path(model.pallet_id)
    elsif model.container_id
      container_container_items_path(model.container_id)
    end
  end

  def unpack_path
    if model.box_id
      box_box_item_box_unpacking_events_path(model.box_id, model)
    elsif model.pallet_id
      pallet_pallet_item_pallet_unpacking_events_path(model.pallet_id, model)
    elsif model.container_id
      container_container_item_container_unpacking_events_path(model.container_id, model)
    end
  end
end
