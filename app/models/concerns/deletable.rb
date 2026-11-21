# frozen_string_literal: true

# How hard a record is to delete. Every model gets the permissive defaults;
# the ones that organize or hold other records override them.
#
# - deletion_blockers: reasons it can't be deleted at all while still in use.
# - requires_typed_delete?: deleting it reaches too far to be a single click, so
#   the person must type "delete" in the confirm dialog (and the server checks
#   they did). Items, shipments and containers always; boxes and pallets once
#   they're Received.
# - deletion_impact: plain sentences saying what else deleting it changes, for
#   the dialog. Only asked for on a record's own page, since it runs queries.
module Deletable
  extend ActiveSupport::Concern

  CONFIRM_WORD = "delete"

  def deletion_blockers
    []
  end

  def requires_typed_delete?
    false
  end

  def deletion_impact
    []
  end

  private

  # "3 boxes", "1 box"
  def count_of(count, noun)
    "#{count} #{noun.pluralize(count)}"
  end

  # Packed lines in `scope` and the unpacking records that go with them.
  def packed_lines_deleted(scope, where)
    lines = scope.count
    return [] if lines.zero?

    events = UnpackingEvent.where(packed_item_id: scope.select(:id)).count
    sentence = "#{count_of(lines, "packed item")} #{where} will be deleted"
    sentence += ", along with #{count_of(events, "unpacking record")}" if events.positive?
    ["#{sentence}."]
  end
end
