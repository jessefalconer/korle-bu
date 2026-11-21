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

  # What this record sits in, outermost first, ending with itself: its shipment,
  # container and pallet, whichever apply. Drives both the page breadcrumbs and
  # the nested "Located in" list on unpack forms.
  def location_chain
    [(shipment unless model.is_a?(Shipment)), parent_container, (pallet if model.is_a?(Box)), model].compact.uniq
  end

  def breadcrumbs
    safe_join(location_chain.map { |record| tag.li(link_to(record.name, url_for(record)), class: "breadcrumb-item") })
  end

  def breadcrumbs_item
    breadcrumbs + tag.li("Items", class: "breadcrumb-item active")
  end

  # Each level indented under the one it sits in, as a nested list.
  def location_tree
    location_chain.reverse.inject(nil) do |inner, record|
      tag.ul(class: "location-tree") do
        tag.li { safe_join([link_to(record.name, url_for(record)), inner].compact) }
      end
    end
  end

  private

  # A box's container, directly or through its pallet; a pallet's container.
  def parent_container
    if model.is_a?(Box)
      container || pallet&.container
    elsif model.is_a?(Pallet)
      container
    end
  end
end
