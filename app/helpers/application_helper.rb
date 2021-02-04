# frozen_string_literal: true

module ApplicationHelper
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

  def link_index_button(path, icon)
    link_to(path, class: "btn btn-primary hidden-sm hidden-md hidden-lg") do
      tag.i("", class: "fa fa-th-list") +
        tag.span(" ") +
        tag.i("", class: "fa #{icon}")
    end
  end

  def submit_button_redirect(text, redirect = "")
    button_tag(type: "submit", name: "redirect", value: redirect, class: "btn btn-primary responsive-button") do
      tag.i("", class: "fa fa-save") +
        tag.span(" #{text}", class: "main-text")
    end
  end

  def submit_button_responsive(text, classes = "")
    button_tag(type: "submit", class: "btn btn-primary responsive-button #{classes}") do
      tag.i("", class: "fa fa-save") +
        tag.span(" #{text}", class: "main-text")
    end
  end

  def submit_export
    button_tag(type: "submit", class: "btn btn-primary left") do
      tag.span("Export ", class: "main-text") +
      tag.i("", class: "fa fa-file-export")
    end
  end

  def submit_button(text, classes = "", icon = "fa-save")
    button_tag(type: "submit", class: "btn btn-primary #{classes}") do
      tag.i("", class: "fa #{icon}") +
        tag.span(" #{text}")
    end
  end

  def submit_button_warning(text, classes = "")
    button_tag(type: "submit", class: "btn btn-danger responsive-button #{classes}") do
      tag.i("", class: "fa fa-compress-alt") +
        tag.span(" #{text}", class: "main-text")
    end
  end

  def swap_button(path, classes = "")
    link_to(path, class: "btn btn-warning #{classes}") do
      tag.i("", class: "fa fa-exchange-alt fa-rotate-90") +
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
      tag.i("", class: "fa fa-tasks") +
        tag.span(" ") +
        tag.span("#{text} ", class: "main-text") +
        tag.i("", class: "fa #{icon}")
    end
  end

  def sortable(column, title = nil)
    title ||= column.titleize
    css_class = column == sort_column ? "current fa #{sort_direction}" : nil
    direction = column == sort_column && sort_direction == "desc" ? "asc" : "desc"

    link_to({sort: column, direction: direction}) do
      tag.span("#{title} ") +
      tag.i("", class: css_class)
    end
  end

  def present(model)
    klass = "#{model.class}Presenter".constantize
    presenter = klass.new(model, self)
    yield(presenter) if block_given?

    presenter
  end
end
