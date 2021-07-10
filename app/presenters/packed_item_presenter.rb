# frozen_string_literal: true

class PackedItemPresenter < BasePresenter
  def path
    case parent.class.name
    when "Box"
      box_box_items_path(parent)
    when "Pallet"
      pallet_pallet_items_path(parent)
    when "Container"
      container_container_items_path(parent)
    end
  end

  def unpack_path
    case parent.class.name
    when "Box"
      box_box_item_box_unpacking_events_path(parent, self)
    when "Pallet"
      pallet_pallet_item_pallet_unpacking_events_path(parent, self)
    when "Container"
      container_container_item_container_unpacking_events_path(parent, self)
    end
  end
end
