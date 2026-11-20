# frozen_string_literal: true

module ApplicationHelper
  # Sorts a collection newest-first by `column`. A preloaded association is sorted in
  # memory, because calling `.order` on it would throw away the preload and query again.
  def sorted_desc(records, column, preload: nil)
    if records.respond_to?(:loaded?) && records.loaded?
      records.sort_by { |r| r.public_send(column) }.reverse
    else
      relation = records.order(column => :desc)
      preload ? relation.preload(preload) : relation
    end
  end

  # <option> tags for the hospital dropdown. Unpack forms render one dropdown per
  # packed item, so the options are built once per request and reused.
  def hospital_options
    @hospital_options ||= options_from_collection_for_select(
      Hospital.accessible_by(current_ability).order(:name), :id, :name
    )
  end

  def delete_button(path, confirm_text, classes = "")
    link_to(path, class: "btn btn-danger responsive-button #{classes}", data: { confirm: confirm_text, method: :delete }) do
      tag.i("", class: "fa fa-trash") +
        tag.span(" Delete", class: "main-text")
    end
  end

  def link_button(text, path, side = "", data = {})
    link_to(path, class: "btn btn-primary #{side}", data: data) do
      tag.span(text)
    end
  end

  def link_refresh_button(path, text, icon)
    link_to(path, class: "btn btn-primary") do
      tag.span("#{text} ") +
        tag.i("", class: "fa #{icon}")
    end
  end

  def link_index_button(path, icon)
    link_to(path, class: "btn btn-primary d-sm-none") do
      tag.i("", class: "fa fa-table-list") +
        tag.span(" ") +
        tag.i("", class: "fa #{icon}")
    end
  end

  def submit_button_redirect(text, redirect = "", icon = nil)
    icon ||= "fa-floppy-disk"
    button_tag(type: "submit", name: "redirect", value: redirect, class: "btn btn-primary responsive-button") do
      tag.i("", class: "fa #{icon}") +
        tag.span(" #{text}", class: "main-text")
    end
  end

  def submit_button_responsive(text, classes = "")
    button_tag(type: "submit", class: "btn btn-primary responsive-button #{classes}") do
      tag.i("", class: "fa fa-floppy-disk") +
        tag.span(" #{text}", class: "main-text")
    end
  end

  def submit_export
    button_tag(type: "submit", class: "btn btn-primary left") do
      tag.span("Export ", class: "main-text") +
        tag.i("", class: "fa fa-file-export")
    end
  end

  def submit_button(text, classes = "", icon = "fa-floppy-disk")
    button_tag(type: "submit", class: "btn btn-primary #{classes}") do
      tag.i("", class: "fa #{icon}") +
        tag.span(" #{text}")
    end
  end

  def submit_button_value(icons = [], value = "")
    if value.blank?
      button_tag(type: "submit", class: "btn btn-primary") do
        safe_join(icons.map { |icon| tag.i("", class: "fa #{icon}") + tag.span(" ") })
      end
    else
      button_tag(type: "submit", class: "btn btn-primary", value: value) do
        safe_join(icons.map { |icon| tag.i("", class: "fa #{icon}") + tag.span(" ") })
      end
    end
  end

  def submit_button_warning(text, classes = "")
    button_tag(type: "submit", class: "btn btn-danger responsive-button #{classes}") do
      tag.i("", class: "fa fa-down-left-and-up-right-to-center") +
        tag.span(" #{text}", class: "main-text")
    end
  end

  def swap_button(classes = "")
    button_tag(type: "submit", class: "btn btn-warning btn-xs #{classes} swap-button") do
      tag.i("", class: "fa fa-right-left") +
        tag.span(" Swap", class: "main-text")
    end
  end

  def add_button(path, text, icon)
    link_to(path, class: "btn btn-primary responsive-button") do
      tag.i("", class: "fa fa-plus") +
        tag.span(" ") +
        tag.span("#{text} ", class: "main-text") +
        tag.i("", class: "fa #{icon}")
    end
  end

  def manage_button(path, text, icon)
    link_to(path, class: "btn btn-primary responsive-button") do
      tag.i("", class: "fa fa-list-check") +
        tag.span(" ") +
        tag.span("#{text} ", class: "main-text") +
        tag.i("", class: "fa #{icon}")
    end
  end

  # A status in its colour (the status-* classes) with a thin outline in the same colour.
  # The outline is on an inner span, so the outer element can stay a full-height table
  # link. "N/A" means there is no status, so it gets the colour but no outline.
  def status_label(status, tag_name = :p, classes: nil, color_class: "status-#{status.to_s.parameterize}")
    content_tag(tag_name, class: [color_class, classes].compact.join(" ")) do
      status == "N/A" ? status : tag.span(status, class: "status-pill")
    end
  end

  def present(model)
    klass = "#{model.class}Presenter".constantize
    presenter = klass.new(model, self)
    yield(presenter) if block_given?

    presenter
  end
end
