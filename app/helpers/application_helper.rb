# frozen_string_literal: true

module ApplicationHelper
  def submit_button(text, data = {})
    button_tag(type: "submit", class: "button submit", data: data) do
      content_tag(:span, text, class: "button-text") + content_tag(:i, "", class: "fa fa-arrow-right")
    end
  end

  def link_button(text, path, data = {})
    link_to(path, class: "button submit", data: data) do
      content_tag(:span, text, class: "button-text") + content_tag(:i, "", class: "fa fa-arrow-right")
    end
  end

  def table_button(text, path, data = {})
    link_to(path, class: "button view", data: data) do
      content_tag(:span, text, class: "button-text") + content_tag(:i, "", class: "fa fa-arrow-right")
    end
  end

  def delete_button(path, _data = {})
    link_to(path, class: "button delete", method: :delete) do
      content_tag(:span, "Delete", class: "button-text") + content_tag(:i, "", class: "fa fa-trash")
    end
  end

  def edit_button(path, data = {})
    link_to(path, class: "button submit", data: data) do
      content_tag(:span, "Edit", class: "button-text") + content_tag(:i, "", class: "fa fa-arrow-right")
    end
  end

  def back_button(path, text = "Back", data = {})
    link_to(path, class: "button view", data: data) do
      content_tag(:i, "", class: "fa fa-arrow-left") + content_tag(:span, text, class: "button-text")
    end
  end

  def next_button(path, text = "Back", data = {})
    link_to(path, class: "button view", data: data) do
      content_tag(:i, "", class: "fa fa-arrow-down") +
        content_tag(:span, text, class: "button-text") +
        content_tag(:i, "", class: "fa fa-arrow-down")
    end
  end
end
