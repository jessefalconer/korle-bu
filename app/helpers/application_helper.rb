# frozen_string_literal: true

module ApplicationHelper
  # The unpack forms have always counted "today" in this zone.
  UNPACK_TIME_ZONE = "Pacific Time (US & Canada)"

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

  # Where the Help page (public/help.html) opens for this person: their role's section
  def help_section_for(user)
    if user.admin? then "admins"
    elsif user.shipping_manager? then "shipping"
    elsif user.receiving_manager? then "receiving"
    else "volunteers"
    end
  end

  # What the app runs on, shown at the foot of the sidebar: [name, logo, version]
  def stack_versions
    [
      ["Ruby", "stack/ruby.svg", RUBY_VERSION],
      ["Rails", "stack/rails.svg", Rails.version],
      ["PostgreSQL", "stack/postgresql.svg", ApplicationHelper.postgres_version]
    ]
  end

  # Asked once per server process: the database doesn't change version while it runs.
  # "18.7 (Homebrew)" becomes "18.7".
  def self.postgres_version
    @postgres_version ||= ActiveRecord::Base.connection.select_value("SHOW server_version").split.first
  end

  # Category dropdown choices, loaded once per page (list pages render an item
  # form per row).
  def category_choices
    @category_choices ||= Category.order(:name).pluck(:name, :id)
  end

  # How many packed items use each of these items, in one query (for list pages
  # that show an "Instances" column).
  def instance_counts(items)
    ids = items.map(&:id)
    ids.empty? ? {} : PackedItem.where(item_id: ids).group(:item_id).count
  end

  # Unpack forms start on the hospital this person last unpacked to in this
  # session, so unpacking several boxes for one clinic needs no re-picking.
  def hospital_options
    @hospital_options ||= options_from_collection_for_select(
      Hospital.accessible_by(current_ability).order(:name), :id, :name, session.dig(:last_unpack, "hospital_id")
    )
  end

  # The date unpack forms start on: the one last used, if that was chosen today
  # (so a backdated entry never carries over to tomorrow), otherwise today.
  def unpack_date
    today = DateTime.current.in_time_zone(UNPACK_TIME_ZONE).strftime("%Y-%m-%d")
    last = session[:last_unpack] || {}
    last["chosen_on"] == today && last["date"].present? ? last["date"] : today
  end

  # A Delete button that asks first. Pass `record:` and, if deleting it reaches
  # beyond itself (Deletable#requires_typed_delete?), the dialog also asks for
  # "delete" to be typed and lists what else changes. `details: false` skips that
  # list (it runs queries) where many delete buttons share a page.
  def delete_button(path, confirm_text, classes = "", record: nil, details: true)
    data = { confirm: confirm_text, method: :delete }
    if record&.requires_typed_delete?
      data[:confirm_word] = Deletable::CONFIRM_WORD
      data[:confirm_details] = record.deletion_impact.to_json if details
    end

    link_to(path, class: "btn btn-danger responsive-button #{classes}", data: data) do
      tag.i("", class: "fa fa-trash") +
        tag.span(" Delete", class: "main-text")
    end
  end

  def link_button(text, path, side = "", data = {})
    link_to(path, class: "btn btn-primary #{side}", data: data) do
      tag.span(text)
    end
  end

  # Jump To shortcut: "Latest [icon] Pallet" with an arrow at the far end
  def latest_link(name, path, icon)
    link_to(path, class: "btn latest-link") do
      tag.span("Latest") +
        tag.i("", class: "fa #{icon}") +
        tag.span(name, class: "latest-link-name") +
        tag.i("", class: "fa fa-arrow-right latest-link-arrow")
    end
  end

  def link_refresh_button(path, text, icon)
    link_to(path, class: "btn btn-primary responsive-button") do
      tag.i("", class: "fa #{icon}") +
        tag.span(" #{text}", class: "main-text")
    end
  end

  def link_index_button(path, icon)
    link_to(path, class: "btn btn-primary d-sm-none") do
      tag.i("", class: "fa fa-table-list") +
        tag.span(" ") +
        tag.i("", class: "fa #{icon}")
    end
  end

  # trailing_icon: an icon after the label, e.g. an arrow for a button that saves and
  # then moves on to another page
  def submit_button_redirect(text, redirect = "", icon = nil, trailing_icon: nil)
    icon ||= "fa-floppy-disk"
    button_tag(type: "submit", name: "redirect", value: redirect, class: "btn btn-primary responsive-button") do
      content = tag.i("", class: "fa #{icon}") + tag.span(" #{text}", class: "main-text")
      trailing_icon ? content + tag.i("", class: "fa #{trailing_icon} btn-trailing-icon") : content
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
      tag.i("", class: "fa fa-file-export") +
        tag.span(" Export", class: "main-text")
    end
  end

  # Pass icon: nil for a text-only button
  def submit_button(text, classes = "", icon = "fa-floppy-disk")
    button_tag(type: "submit", class: "btn btn-primary #{classes}") do
      label = tag.span(text)
      icon ? tag.i("", class: "fa #{icon}") + label : label
    end
  end

  # Button for the Jump To searches, built from icons ("fa-…") and words in order, e.g.
  # ["fa-box-open", "Box's", "fa-stethoscope", "Items", "fa-arrow-right"]. The words
  # show on desktop only; phones get the icons alone.
  def submit_button_value(parts = [], value = "")
    content = parts.map do |part|
      if part.start_with?("fa-")
        tag.i("", class: "fa #{part}")
      else
        tag.span(part, class: "d-none d-md-inline")
      end
    end

    button_tag(type: "submit", class: "btn btn-primary", value: value.presence) do
      safe_join(content)
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

  def add_button(path, text)
    link_to(path, class: "btn btn-primary responsive-button") do
      tag.i("", class: "fa fa-plus") +
        tag.span(" #{text}", class: "main-text")
    end
  end

  def manage_button(path, text)
    link_to(path, class: "btn btn-primary responsive-button") do
      tag.i("", class: "fa fa-list-check") +
        tag.span(" #{text}", class: "main-text")
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
