# frozen_string_literal: true

class DashboardStats
  # Where unpacked supplies went: for one warehouse (a receiving manager's own)
  # or across every warehouse (admins). Dates use the event's timestamp, the
  # "when" people record and can correct, rather than when the row was saved.
  class Unpacking < DashboardStats
    QUIET_AFTER = 90.days
    TIME = "unpacking_events.timestamp"

    attr_reader :warehouse

    # Every warehouse only when asked for explicitly: a missing warehouse
    # (a receiving manager not assigned to one yet) means nothing, not everything.
    def initialize(user, range: nil, warehouse: nil, everywhere: false)
      super(user, range: range)
      @warehouse = warehouse
      @everywhere = everywhere
    end

    def all_warehouses?
      @everywhere
    end

    def summary
      cached("unpacking_summary") do
        units, units_before = window_sums(events, column: TIME, sum: "unpacking_events.quantity")
        handovers, handovers_before = window_sums(events, column: TIME)
        served, served_before = window_sums(events, column: TIME, aggregate: "COUNT(DISTINCT unpacking_events.hospital_id)")
        {
          units: Tile.new(label: "Units unpacked", value: units, previous: units_before, good: :up),
          handovers: Tile.new(label: "Handovers", value: handovers, previous: handovers_before, good: :up),
          served: Tile.new(label: "Destinations supplied", value: served, previous: served_before, good: :up),
          per_handover: handovers.zero? ? 0 : (units / handovers.to_f).round
        }
      end
    end

    def weekly_units
      cached("unpacking_weekly", period: false) { weekly_series(events, column: TIME, sum: "unpacking_events.quantity") }
    end

    def by_destination
      cached("unpacking_destinations") { top(events.group("hospitals.name"), limit: 8) }
    end

    # Only meaningful across warehouses.
    def by_warehouse
      cached("unpacking_warehouses") { top(events.joins(hospital: :warehouse).group("warehouses.name"), limit: 8) }
    end

    def top_items
      cached("unpacking_items") { top(events.joins(packed_item: :item).group("items.generated_name")) }
    end

    def by_category
      cached("unpacking_categories") do
        top(events.joins(packed_item: :item)
              .joins("LEFT JOIN categories ON categories.id = items.category_id")
              .group(Arel.sql("COALESCE(categories.name, 'Uncategorized')")))
      end
    end

    # Destinations that received something for the very first time this period
    # (meaningless for all time, where every destination is a first).
    def first_time_destinations
      return [] if all_time?

      cached("unpacking_first_time") do
        firsts = events.group("hospitals.id", "hospitals.name").minimum(TIME)
        firsts.select { |_key, first| first >= period_start }.map { |(_id, name), _first| name }.sort
      end
    end

    # Active destinations that haven't been sent anything lately, longest-waiting first.
    def quiet_destinations
      cached("unpacking_quiet", period: false) do
        last_by_hospital = destinations.left_joins(:unpacking_events)
          .group(:id, :name)
          .maximum(TIME)
        last_by_hospital
          .select { |_key, last| last.nil? || last < QUIET_AFTER.ago }
          .sort_by { |(_id, name), last| [last ? 1 : 0, last || Time.zone.at(0), name] }
          .map { |(id, name), last| { id: id, name: name, last: last&.to_date } }
      end
    end

    private

    def events
      scope = UnpackingEvent.joins(:hospital)
      return scope if all_warehouses?

      warehouse ? scope.where(hospitals: { warehouse_id: warehouse.id }) : scope.none
    end

    def destinations
      scope = Hospital.where(status: Hospital::ACTIVE)
      return scope if all_warehouses?

      warehouse ? scope.where(warehouse_id: warehouse.id) : scope.none
    end

    # The biggest groups this period by units, as [name, units] pairs.
    def top(grouped, limit: LEADERBOARD_SIZE)
      in_period(grouped, TIME)
        .order(Arel.sql("SUM(unpacking_events.quantity) DESC"))
        .limit(limit)
        .sum(:quantity)
        .to_a
    end

    def cache_scope
      [all_warehouses? ? "all-warehouses" : "warehouse-#{warehouse&.id || "none"}"]
    end
  end
end
