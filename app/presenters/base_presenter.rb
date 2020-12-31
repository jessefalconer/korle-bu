# frozen_string_literal: true

class BasePresenter < SimpleDelegator
  include ActionView::Helpers
  include ActionView::Context
  include Haml::Helpers
  include Rails.application.routes.url_helpers

  def initialize(model, view)
    @view = view
    super(model)
  end

  def h
    @view
  end

  def model
    __getobj__
  end

  def breadcrumbs
    a = if model.class != Shipment && shipment
      tag.li do
        link_to shipment.name, shipment_path(shipment)
      end
    end

    b = if (model.instance_of?(Box) || model.instance_of?(Pallet)) && container
      tag.li do
        link_to container.name, container_path(container)
      end
    end

    c = if model.instance_of?(Box) && pallet
      tag.li do
        link_to pallet.name, pallet_path(pallet)
      end
    end

    d = tag.li do
      link_to model.name, url_for(model)
    end

    safe_join [a, b, c, d]
  end

  def breadcrumbs_item
    breadcrumbs + tag.li(class: "active") do
      "Items"
    end
  end
end
