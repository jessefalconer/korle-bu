# frozen_string_literal: true

class PalletPresenter < BasePresenter
  def container_location
    status = container&.status || "N/A"

    tag.td do
      if container
        link_to(container_path(container)) do
          tag.p(container.name)
        end
      else
        tag.p("N/A", class: "status-n-a")
      end
    end +
      tag.td do
        h.status_label(status, classes: "float-end")
      end
  end

  def shipment_location
    status = shipment&.status || "N/A"

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
        h.status_label(status, classes: "float-end")
      end
  end

  def warehouse_location
    location = shipment&.current_location || "N/A"
    status = shipment&.status.presence || "N/A"

    tag.td do
      tag.p(location, class: "status-#{location.parameterize}")
    end +
      tag.td do
        h.status_label(status, classes: "float-end")
      end
  end
end
