# frozen_string_literal: true

require "csv"

# One-off clean-up: moves serial numbers that were typed into an item's brand or
# name ("Serial #R30922", "S/N YC17212BQ", "(S/N ? 717076051859)") into the
# serial_number column, and takes them out of the text they were in.
#
# Run through the rake tasks in lib/tasks/items.rake:
#   plan      - what would change, for every item mentioning a serial (reads only)
#   apply!    - makes the automatic changes, after writing a backup CSV
#   restore!  - puts items back exactly as a backup recorded them
# Anything ambiguous (no value, two serials, "illegible", extra words) is left
# for a person, with the reason.
class SerialNumberExtraction
  FIELDS = %i[brand object].freeze
  # Any of these, in brand, name or notes, marks an item worth looking at
  MENTION_SQL = 's\s*/\s*n|serial|\msn\M'

  MARKER = %r{
    (?<lead>\s*[-,;]?\s*\(?\s*)                     # separator before, maybe an opening paren
    (?<marker>serial\s*(?:no\.?|number|num|\#)?|s\s*/\s*n|\bsn\b)
    \s*[:\#.?]*\s*                                  # "#", ":", "?" after the marker
    (?<value>[^,;/()]*?)                            # the serial, up to a separator
    \s*(?<close>\))?                                # closing paren of "(S/N ...)"
    (?=\s*(?:[,;/)]|\z|\s-\s))
  }ix

  NOT_A_SERIAL = %r{\A(illegible|unknown|n/?a|none|missing|unreadable|\?+)\z}i
  LONGEST_SERIAL = 24

  # What to do with one item. status is :auto, :review or :skip (notes only).
  Change = Struct.new(:item, :status, :reason, :field, :before, :after, :serial, :new_name, keyword_init: true) do
    def auto?
      status == :auto
    end
  end

  # What to do with one piece of text: a serial and the text without it, or why not.
  def self.propose(text)
    matches = text.to_s.to_enum(:scan, MARKER).map { Regexp.last_match }
    return if matches.empty?
    return { reason: "#{matches.size} serial markers" } if matches.size > 1

    match = matches.first
    value = match[:value].strip.sub(/\A[#:?\s]+/, "")
    return { reason: "says there's no serial" } if text.match?(/\bno\s+serial/i)
    return { reason: "marker with no value" } if value.empty?
    return { reason: "not a serial: #{value}" } if value.match?(NOT_A_SERIAL)
    return { reason: "serial looks long (#{value.length} chars)" } if value.length > LONGEST_SERIAL

    # What's left either side of the serial, joined with ", " when both have words
    before = text[0...match.begin(0)].sub(%r{[\s,;:/-]+\z}, "")
    after = text[match.end(0)..].sub(%r{\A[\s,;:/-]+}, "")
    { serial: value, rest: [before, after].compact_blank.join(", ").gsub(/\(\s*\)/, "").squish }
  end

  # Every item mentioning a serial, with what would happen to it.
  def self.plan(scope = Item.all)
    new_names = {}
    scope.where("brand ~* :r OR object ~* :r OR notes ~* :r", r: MENTION_SQL).order(:id).map do |item|
      change = change_for(item, new_names)
      new_names[change.new_name] = item.id if change.auto?
      change
    end
  end

  def self.change_for(item, new_names)
    proposals = FIELDS.filter_map { |field| (proposal = propose(item[field])) && [field, proposal] }
    return Change.new(item: item, status: :skip, reason: "mentioned in notes only") if proposals.empty?
    return Change.new(item: item, status: :review, reason: "serial in both brand and name") if proposals.size > 1

    field, proposal = proposals.first
    change = Change.new(item: item, field: field, before: item[field])
    unless proposal[:serial]
      change.status = :review
      change.reason = proposal[:reason]
      return change
    end

    change.after = proposal[:rest].presence
    change.serial = proposal[:serial]
    change.new_name = name_with(item, field, change.after, change.serial)
    change.status, change.reason = check_new_name(item, field, change, new_names)
    change
  end

  def self.name_with(item, field, value, serial)
    candidate = item.dup
    candidate[field] = value
    candidate.serial_number = serial
    candidate.process_name.presence || "Unnamed Item"
  end

  def self.check_new_name(item, field, change, new_names)
    if (field == :object ? change.after : item.object).blank?
      [:review, "name would be empty without the serial"]
    elsif new_names.key?(change.new_name) || Item.where.not(id: item.id).exists?(generated_name: change.new_name)
      [:review, "new name would duplicate another item"]
    else
      [:auto, nil]
    end
  end

  # ------------------------------------------------------------ Files

  PREVIEW_HEADERS = ["Item ID", "Link", "Status", "Why review", "Field", "Field now", "Field after", "Serial",
                     "Name now", "Name after", "Packed instances"].freeze

  # Review rows first, then the automatic ones
  def self.write_preview(changes, path)
    counts = PackedItem.where(item_id: changes.map { |c| c.item.id }).group(:item_id).count
    CSV.open(path, "w") do |csv|
      csv << PREVIEW_HEADERS
      changes.reject { |c| c.status == :skip }.sort_by { |c| [c.auto? ? 1 : 0, c.item.id] }.each do |c|
        csv << [c.item.id, "/items/#{c.item.id}", c.status, c.reason, c.field, c.before, c.after, c.serial,
                c.item.generated_name, c.new_name, counts.fetch(c.item.id, 0)]
      end
    end
  end

  def self.summary(changes)
    changes.group_by(&:status).transform_values(&:size)
  end

  # ------------------------------------------------------------ Applying and undoing

  BACKUP_HEADERS = %w[id brand object serial_number generated_name].freeze

  # Makes the automatic changes in one transaction, after writing every touched
  # item's old values to `backup_path`. An item edited since the plan was made
  # (its field no longer matches) is skipped. Returns [applied, skipped] counts.
  def self.apply!(changes, backup_path)
    auto = changes.select(&:auto?)
    CSV.open(backup_path, "w") do |csv|
      csv << BACKUP_HEADERS
      auto.each { |c| csv << BACKUP_HEADERS.map { |column| c.item[column] } }
    end

    applied = 0
    Item.transaction do
      auto.each do |change|
        item = Item.lock.find(change.item.id)
        next unless item[change.field] == change.before && item.serial_number.blank?

        item.update!(change.field => change.after, serial_number: change.serial)
        applied += 1
      end
    end
    [applied, auto.size - applied]
  end

  # Puts every item in a backup back exactly as it was, name included.
  def self.restore!(backup_path)
    rows = CSV.read(backup_path, headers: true)
    Item.transaction do
      rows.each do |row|
        # Straight back to the recorded values: re-running validations or naming
        # could produce something other than what was there before.
        Item.where(id: row["id"]).update_all( # rubocop:disable Rails/SkipsModelValidations
          row.to_h.slice(*BACKUP_HEADERS.drop(1)).merge("updated_at" => Time.current)
        )
      end
    end
    rows.size
  end
end
