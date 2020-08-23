# frozen_string_literal: true

class PalletPresenter < BasePresenter
  def container_location
    status = container&.status&.presence || "Unassigned"

    content_tag(:td) do
      if container
        link_to(container_path(container)) do
          content_tag(:p, container.name)
        end
      else
        content_tag(:p, "")
      end
    end +
    content_tag(:td) do
      content_tag(:p, status, class: "pull-right")
    end
  end

  def shipment_location
    status = shipment&.status&.presence || "Unassigned"

    content_tag(:td) do
      if shipment
        link_to(shipment_path(shipment)) do
          content_tag(:p, shipment.name)
        end
      else
        content_tag(:p, "")
      end
    end +
    content_tag(:td) do
      content_tag(:p, status, class: "pull-right")
    end
  end
end
