# frozen_string_literal: true

class ItemPresenter < BasePresenter
  def match(compare_item)
    arr = generated_name.split(" ")
    str = compare_item
    arr.each do |substr|
      str.gsub!(/#{substr}/i, tag.strong(substr))
    end

    sanitize(str)
  end
end
