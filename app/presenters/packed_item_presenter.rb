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
end
