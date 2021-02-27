# frozen_string_literal: true

class PalletPresenter < BasePresenter
  def container_location
    status = container&.status || "Staged"

    tag.td do
      if container
        link_to(container_path(container)) do
          tag.p(container.name)
        end
      else
        tag.p("N/A", class: "status-staged")
      end
    end +
      tag.td do
        tag.p(status, class: "pull-right status-#{status.parameterize}")
      end
  end

  def shipment_location
    status = shipment&.status || "Staged"

    tag.td do
      if shipment
        link_to(shipment_path(shipment)) do
          tag.p(shipment.name)
        end
      else
        tag.p("N/A", class: "status-staged")
      end
    end +
      tag.td do
        tag.p(status, class: "pull-right status-#{status.parameterize}")
      end
  end

  def warehouse_location
    location = shipment&.current_location || "N/A"
    status = shipment&.status&.presence || "Staged"

    tag.td do
      tag.p(location, class: "status-#{location.parameterize}")
    end +
      tag.td do
        tag.p(status, class: "pull-right status-#{status.parameterize}")
      end
  end
end
