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
    safe_join [breadcrumbs_shipment, breadcrumbs_container, breadcrumbs_pallet, breadcrumbs_box]
  end

  def breadcrumbs_item
    breadcrumbs + tag.li(class: "active") do
      "Items"
    end
  end

  def breadcrumbs_shipment
    return unless model.class != Shipment && shipment

    tag.li do
      link_to shipment.name, shipment_path(shipment)
    end
  end

  def breadcrumbs_container
    if model.instance_of?(Box) && (container || pallet&.container)
      parent_container = container || pallet&.container

      tag.li do
        link_to parent_container.name, container_path(parent_container)
      end
    elsif model.instance_of?(Pallet) && container
      tag.li do
        link_to container.name, container_path(container)
      end
    end
  end

  def breadcrumbs_pallet
    return unless model.instance_of?(Box) && pallet

    tag.li do
      link_to pallet.name, pallet_path(pallet)
    end
  end

  def breadcrumbs_box
    tag.li do
      link_to model.name, url_for(model)
    end
  end
end
