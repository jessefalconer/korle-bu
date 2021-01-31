# frozen_string_literal: true

class BoxPresenter < BasePresenter
  def pallet_location
    status = pallet&.status || "Unassigned"

    tag.td do
      if pallet
        link_to(pallet_path(pallet)) do
          tag.p(pallet.name)
        end
      else
        tag.p("N/A", class: "status-unassigned")
      end
    end +
      tag.td do
        tag.p(status, class: "pull-right status-#{status.parameterize}")
      end
  end

  def container_location
    record = container || pallet&.container
    status = record&.status || "Unassigned"

    tag.td do
      if record
        link_to(container_path(record)) do
          tag.p(record.name)
        end
      else
        tag.p("N/A", class: "status-unassigned")
      end
    end +
      tag.td do
        tag.p(status, class: "pull-right status-#{status.parameterize}")
      end
  end

  def shipment_location
    status = shipment&.status || "Unassigned"

    tag.td do
      if shipment
        link_to(shipment_path(shipment)) do
          tag.p(shipment.name)
        end
      else
        tag.p("N/A", class: "status-unassigned")
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
