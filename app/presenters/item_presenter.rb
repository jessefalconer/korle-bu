# frozen_string_literal: true

class ItemPresenter < BasePresenter
  def bar_color(value, max_value)

    case parent.class.name
    when "Box"
      box_box_items_path(parent)
    when "Pallet"
      pallet_pallet_items_path(parent)
    when "Container"
      container_container_items_path(parent)
    end
  end

  def self.percentage(value, max_value)
    1
  end
end
