# frozen_string_literal: true

class PalletPresenter < BasePresenter
  def container_location
    status = container&.status || "Unassigned"

    tag.td do
      if container
        link_to(container_path(container)) do
          tag.p(container.name)
        end
      else
        tag.p("N/A")
      end
    end +
      tag.td do
        tag.p(status, class: "pull-right")
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
        tag.p("N/A")
      end
    end +
      tag.td do
        tag.p(status, class: "pull-right")
      end
  end

  def warehouse_location
    status = shipment&.current_location || "N/A"

    tag.td do
      tag.p(status)
    end +
      tag.td do
        tag.p(shipment&.status&.presence || "Unassigned", class: "pull-right")
      end
  end
end
