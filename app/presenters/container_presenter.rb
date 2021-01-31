# frozen_string_literal: true

class ContainerPresenter < BasePresenter
  def shipment_location
    status = shipment&.status || "Unassigned"

    tag.td do
      if shipment
        link_to(shipment_path(shipment)) do
          tag.p(shipment.name)
        end
      else
        tag.p("N/A", class: "status-n-a")
      end
    end +
      tag.td do
        tag.p(status, class: "pull-right status-#{status.parameterize}")
      end
  end

  def warehouse_location
    location = shipment&.current_location || "N/A"
    status = shipment&.status&.presence || "Unassigned"

    tag.td do
      tag.p(location, class: "status-#{location.parameterize}")
    end +
      tag.td do
        tag.p(status, class: "pull-right status-#{status.parameterize}")
      end
  end
end
