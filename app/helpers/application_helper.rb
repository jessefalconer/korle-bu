# frozen_string_literal: true

module ApplicationHelper
  def delete_button(path, confirm_text, classes = "")
    link_to(path, class: "btn btn-danger responsive-button #{classes}", data: { confirm: confirm_text, method: :delete }) do
      tag.i("", class: "fa fa-trash") +
        tag.span(" Delete")
    end
  end

  def link_button(text, path, side = "", data = {})
    link_to(path, class: "btn btn-primary #{side}", data: data) do
      tag.span(text)
    end
  end

  def submit_button_responsive(text, classes = "")
    button_tag(type: "submit", class: "btn btn-primary responsive-button #{classes}") do
      tag.i("", class: "fa fa-save") +
        tag.span(" #{text}")
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
        tag.span(" #{text}")
    end
  end

  def swap_button(path, classes = "")
    link_to(path, class: "btn btn-warning responsive-button #{classes}") do
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

  def present(model)
    klass = "#{model.class}Presenter".constantize
    presenter = klass.new(model, self)
    yield(presenter) if block_given?

    presenter
  end
end
