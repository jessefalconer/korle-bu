# frozen_string_literal: true

class BoxPresenter < BasePresenter
  def pallet_location
    status = pallet&.status&.presence || "Unassigned"

    tag.td do
      if pallet
        link_to(pallet_path(pallet)) do
          tag.p(pallet.name)
        end
      else
        tag.p("")
      end
    end +
      tag.td do
        tag.p(status, class: "pull-right")
      end
  end

  def container_location
    status = container&.status&.presence || "Unassigned"

    tag.td do
      if container
        link_to(container_path(container)) do
          tag.p(container.name)
        end
      else
        tag.p("")
      end
    end +
      tag.td do
        tag.p(status, class: "pull-right")
      end
  end

  def shipment_location
    status = shipment&.status&.presence || "Unassigned"

    tag.td do
      if shipment
        link_to(shipment_path(shipment)) do
          tag.p(shipment.name)
        end
      else
        tag.p("")
      end
    end +
      tag.td do
        tag.p(status, class: "pull-right")
      end
  end
end
