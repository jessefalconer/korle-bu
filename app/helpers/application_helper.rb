# frozen_string_literal: true

module ApplicationHelper
  def edit_icon(path)
    link_to(path) do
      content_tag(:i, "", class: "fa fa-pencil")
    end
  end

  def delete_icon(path, confirm_text)
    link_to(path, data: { confirm: confirm_text }, method: :delete) do
      content_tag(:i, "", class: "fa fa-trash")
    end
  end

  def delete_button(path, confirm_text, classes = "")
    link_to(path, class: "btn btn-danger responsive-button #{classes}", data: { confirm: confirm_text, method: :delete }) do
      content_tag(:i, "", class: "fa fa-trash") +
      content_tag(:span, " Delete")
    end
  end

  def link_button(text, path, side = "", data = {})
    link_to(path, class: "btn btn-primary #{side}", data: data) do
      content_tag(:span, text)
    end
  end

  def submit_button(text, classes = "")
    button_tag(type: "submit", class: "btn btn-primary responsive-button #{classes}") do
      content_tag(:i, "", class: "fa fa-save") +
        content_tag(:span, " #{text}")
    end
  end

  def present(model)
    klass = "#{model.class}Presenter".constantize
    presenter = klass.new(model, self)
    yield(presenter) if block_given?

    presenter
  end
end
