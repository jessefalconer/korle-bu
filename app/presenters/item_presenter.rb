# frozen_string_literal: true

class ItemPresenter < BasePresenter
  # Bolds each word of this item's name wherever it appears in compare_item.
  # Words are matched literally (item names can contain regex characters like
  # "(", "+" or "*"), and compare_item is HTML-escaped rather than mutated.
  def match(compare_item)
    words = generated_name.to_s.split.uniq.sort_by { |word| -word.length }
    return compare_item.to_s if words.empty?

    pattern = Regexp.new("(#{words.map { |word| Regexp.escape(word) }.join('|')})", Regexp::IGNORECASE)
    parts = compare_item.to_s.split(pattern)

    safe_join(parts.each_with_index.map { |part, i| i.odd? ? tag.strong(part.capitalize) : part })
  end
end
