# frozen_string_literal: true

class ContainerPresenter < BasePresenter
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
