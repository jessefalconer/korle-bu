# frozen_string_literal: true

# Everything the dashboard shows, computed in a handful of grouped queries.
# Numbers shared by everyone (totals, leaderboards, trends) are cached for a
# few minutes, since the dashboard is the page everyone lands on. Anything
# about the viewer (their rank, streak, milestones) is worked out per request.
class DashboardStats
  # The ?range= values the dashboard offers, with their button labels.
  RANGES = { "30" => "30 days", "year" => "Year", "all" => "All time" }.freeze
  DEFAULT_RANGE = "year"
  PERIOD_LENGTHS = { "30" => 30.days, "year" => 365.days }.freeze
  CACHE_TTL = 10.minutes
  WEEKS = 12
  LEADERBOARD_SIZE = 5
  ELEPHANT_KG = 5_000
  MILESTONES = [10, 50, 100, 250, 500, 1_000, 2_500, 5_000, 10_000].freeze

  # A headline number compared with the period before it. `good` says which
  # direction is good news ("up" for things packed, "down" for unverified).
  # `previous` is nil when there is nothing to compare with (all time).
  Tile = Struct.new(:label, :value, :previous, :good, :unit, keyword_init: true) do
    def comparable?
      !previous.nil?
    end

    def change
      return if previous.to_f.zero?

      ((value - previous) / previous.to_f * 100).round
    end

    def direction
      return :none unless comparable?
      return :flat if value == previous

      value > previous ? :up : :down
    end

    def good_news?
      %i[up down].include?(direction) && direction == good
    end
  end

  Board = Struct.new(:key, :title, :subtitle, :rows, keyword_init: true)
  Row = Struct.new(:user_id, :name, :value, keyword_init: true)

  attr_reader :user, :range

  def initialize(user, range: nil)
    @user = user
    @range = RANGES.key?(range.to_s) ? range.to_s : DEFAULT_RANGE
  end

  def all_time?
    range == "all"
  end

  def period_name
    all_time? ? "all time" : "past #{RANGES[range].downcase}"
  end

  def previous_period_name
    "previous #{RANGES[range].downcase}" unless all_time?
  end

  # ------------------------------------------------------------ Shared, cached

  def tiles
    cached("tiles") do
      [
        # "New ..." only makes sense for a period; over all time they're totals.
        tile(all_time? ? "Items created" : "New items", Item.all, good: :up),
        tile("Packed items", PackedItem.all, good: :up),
        tile("Units packed", PackedItem.all, sum: "packed_items.quantity", good: :up),
        tile(all_time? ? "Boxes created" : "New boxes", Box.all, good: :up),
        tile(all_time? ? "Unverified items" : "New unverified items", Item.unverified, good: :down),
        tile(all_time? ? "Uncategorized items" : "New uncategorized items", Item.uncategorized, good: :down)
      ]
    end
  end

  # Packed items per week, oldest first, the current (partial) week last.
  def weekly_packed
    cached("weekly", period: false) { weekly_series(PackedItem.all, column: "packed_items.created_at") }
  end

  def top_categories
    cached("categories") do
      in_period(PackedItem.all, "packed_items.created_at")
        .left_joins(item: :category)
        .group(Arel.sql("COALESCE(categories.name, 'Uncategorized')"))
        .order(Arel.sql("SUM(packed_items.quantity) DESC"))
        .limit(LEADERBOARD_SIZE)
        .sum(:quantity)
        .to_a
    end
  end

  def weight_this_year
    cached("weight_year", period: false) do
      PackedItem.where(created_at: Time.zone.now.beginning_of_year..).sum(:weight).to_f.round
    end
  end

  def elephants_this_year
    (weight_this_year / ELEPHANT_KG.to_f).round(1)
  end

  def leaderboards
    cached("boards") do
      [
        board(:items, "Let There Be Data", "Most items created", Item.all),
        board(:packed, "Industrial-Medical Complex", "Most packed items", PackedItem.all),
        board(:verified, "Wikipedia Contributor", "Most verified items", Item.verified),
        board(:uncategorized, "I Don't Work Here, Lady", "Most uncategorized items", Item.uncategorized)
      ]
    end
  end

  # The viewer's place on a board: nil if they have nothing there this period.
  def rank_on(board)
    index = board.rows.index { |row| row.user_id == user.id }
    index && { rank: index + 1, of: board.rows.size, value: board.rows[index].value }
  end

  def heaviest_item
    cached("heaviest") { highlight(PackedItem.where.not(weight: nil).order(weight: :desc)) { |pi| "#{pi.weight}kg" } }
  end

  def biggest_quantity
    cached("biggest") { highlight(PackedItem.order(quantity: :desc)) { |pi| pi.quantity.to_s } }
  end

  def random_achievement
    User.where.not(achiever_name: nil)
      .where.not(achievement_title: nil)
      .where.not(achievement_description: nil)
      .where.not(achievement_value: nil)
      .where.not(achievement_max_value: nil)
      .order(Arel.sql("RANDOM()"))
      .first
  end

  # Shipments moving through the pipeline, with how much they carry.
  def pipeline
    cached("pipeline", period: false) do
      statuses = [Shipment::IN_PROGRESS, Shipment::COMPLETE, Shipment::RECEIVED]
      counts = Shipment.where(status: statuses).group(:status).count
      weights = PackedItem.joins(:shipment).where(shipments: { status: statuses }).group("shipments.status").sum(:weight)
      units = PackedItem.joins(:shipment).where(shipments: { status: statuses }).group("shipments.status").sum(:quantity)
      statuses.map do |status|
        { status: status, shipments: counts.fetch(status, 0), units: units.fetch(status, 0),
          weight: weights.fetch(status, 0).to_f.round }
      end
    end
  end

  def data_quality
    cached("quality", period: false) do
      total, verified, categorized = Item.pick(
        Arel.sql("COUNT(*), COUNT(*) FILTER (WHERE verified), COUNT(*) FILTER (WHERE category_id IS NOT NULL)")
      )
      { total: total.to_i, verified: verified.to_i, categorized: categorized.to_i }
    end
  end

  # ------------------------------------------------------------ Fun, cached for the day

  def item_of_the_day
    cached("item_of_day", period: false, expires_in: seconds_left_today) do
      pool = Item.verified.categorized
      count = pool.count
      count.zero? ? nil : pool.order(:id).offset(Date.current.jd % count).pick(:id, :generated_name)
    end
  end

  def longest_name
    cached("longest_name") do
      in_period(Item.all, "items.created_at").order(Arel.sql("LENGTH(generated_name) DESC"), :id).pick(:generated_name)
    end
  end

  def newcomers
    cached("newcomers", period: false) do
      User.where(created_at: 14.days.ago.., status: "Active").order(created_at: :desc).limit(5).pluck(:first_name)
    end
  end

  def fact_of_the_day
    cached("fact", period: false, expires_in: seconds_left_today) do
      facts = [
        -> { "KBNF has sent supplies to #{UnpackingEvent.distinct.count(:hospital_id)} hospitals, facilities and clinics." },
        -> { "#{UnpackingEvent.sum(:quantity).to_fs(:delimited)} units have been unpacked and handed over so far." },
        -> { "The item catalogue holds #{Item.count.to_fs(:delimited)} different items." },
        -> { "#{Shipment.where(status: [Shipment::RECEIVED, Shipment::ARCHIVED]).count} shipments have arrived at their destination." },
        -> { "#{Box.count.to_fs(:delimited)} boxes have been packed since records began." }
      ]
      facts[Date.current.jd % facts.size].call
    end
  end

  # ------------------------------------------------------------ The viewer

  def my_totals
    [
      ["Containers created", user.containers.count],
      ["Containerized items", user.container_items.count],
      ["Pallets created", user.pallets.count],
      ["Palletized items", user.pallet_items.count],
      ["Boxes created", user.boxes.count],
      ["Boxed items", user.box_items.count]
    ]
  end

  def my_packed_count
    @my_packed_count ||= PackedItem.where(user_id: user.id).count
  end

  def milestones
    reached = MILESTONES.select { |m| m <= my_packed_count }
    upcoming = MILESTONES.find { |m| m > my_packed_count }
    { count: my_packed_count, reached: reached, next: upcoming }
  end

  # Weeks in a row with at least one packed item. The current week only
  # counts once it has one, so the streak doesn't break on a Monday morning.
  def streak
    weeks = PackedItem.where(user_id: user.id, created_at: 2.years.ago..)
      .distinct
      .pluck(Arel.sql(week_sql("packed_items.created_at")))
      .to_set(&:to_date)
    week = Date.current.beginning_of_week
    week -= 7 unless weeks.include?(week)
    count = 0
    while weeks.include?(week)
      count += 1
      week -= 7
    end
    count
  end

  # Warehouse stock, for receiving managers.
  def receiving
    @receiving ||= Receiving.new(user, range: range)
  end

  # Where unpacked supplies went: the viewer's own warehouse, or every
  # warehouse when `everywhere` (admins).
  def unpacking(everywhere: false)
    @unpacking ||= {}
    @unpacking[everywhere] ||= Unpacking.new(user, range: range, warehouse: user.warehouse, everywhere: everywhere)
  end

  private

  # nil for all time.
  def period_start
    return if all_time?

    @period_start ||= PERIOD_LENGTHS.fetch(range).ago
  end

  def in_period(scope, column)
    period_start ? scope.where(column => period_start..) : scope
  end

  def tile(label, scope, good:, sum: nil)
    now, before = window_sums(scope, column: "#{scope.table_name}.created_at", sum: sum)
    Tile.new(label: label, value: now, previous: before, good: good)
  end

  # This period's and the previous period's totals, in one query.
  # `aggregate` is SQL such as "SUM(x)" or "COUNT(DISTINCT x)"; counts rows by default.
  # Returns [this period, previous period]; the previous one is nil for all time.
  def window_sums(scope, column:, sum: nil, aggregate: nil)
    aggregate ||= sum ? "SUM(#{sum})" : "COUNT(*)"
    return [scope.pick(Arel.sql("COALESCE(#{aggregate}, 0)")).to_i, nil] if all_time?

    filters = "COALESCE(#{aggregate} FILTER (WHERE #{column} >= ?), 0), COALESCE(#{aggregate} FILTER (WHERE #{column} < ?), 0)"
    sql = ActiveRecord::Base.sanitize_sql_array([filters, period_start, period_start])
    now, before = scope.where(column => (period_start - PERIOD_LENGTHS.fetch(range))..).pick(Arel.sql(sql))
    [now.to_i, before.to_i]
  end

  # One value per week for the last WEEKS weeks, oldest first, zeros included,
  # labelled by the week's Monday.
  def weekly_series(scope, column:, sum: nil)
    first_week = (WEEKS - 1).weeks.ago.beginning_of_week
    grouped = scope.where(column => first_week..).group(Arel.sql(week_sql(column)))
    totals = (sum ? grouped.sum(sum) : grouped.count).transform_keys(&:to_date)
    (0...WEEKS).to_h do |i|
      week = (first_week + i.weeks).to_date
      [week.strftime("%b %-d"), totals.fetch(week, 0)]
    end
  end

  def board(key, title, subtitle, scope)
    counts = in_period(scope, "#{scope.table_name}.created_at").group(:user_id).order(Arel.sql("COUNT(*) DESC")).count
    names = User.where(id: counts.keys).pluck(:id, :first_name).to_h
    rows = counts.map { |user_id, value| Row.new(user_id: user_id, name: names[user_id], value: value) }
    Board.new(key: key, title: title, subtitle: subtitle, rows: rows)
  end

  def highlight(scope)
    record = in_period(scope, "packed_items.created_at").preload(:item, :user).first
    record && { name: record.user.first_name, value: yield(record), item: record.generated_name }
  end

  def week_sql(column)
    "DATE_TRUNC('week', #{column} AT TIME ZONE 'UTC' AT TIME ZONE #{ActiveRecord::Base.connection.quote(Time.zone.tzinfo.name)})"
  end

  def seconds_left_today
    (Time.zone.now.end_of_day - Time.zone.now).ceil.seconds
  end

  def cached(name, period: true, per_warehouse: false, expires_in: CACHE_TTL, &)
    key = ["dashboard/v1", name, *cache_scope]
    key << range if period
    key << "warehouse-#{user.warehouse_id}" if per_warehouse
    Rails.cache.fetch(key, expires_in: expires_in, &)
  end

  # Extra cache key parts for subclasses whose numbers depend on more than the period.
  def cache_scope
    []
  end
end
