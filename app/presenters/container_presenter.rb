# frozen_string_literal: true

class ContainerPresenter < BasePresenter
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
