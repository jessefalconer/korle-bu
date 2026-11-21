# frozen_string_literal: true

# The filters above the item, shipment, container, pallet and box lists. Reads
# params[:f] (so it never collides with a page's own params), narrows a scope,
# and tells the filter bar what's selected. Every choice comes from a fixed list
# or is parsed into a date or an id; nothing from the request reaches SQL as text.
#
#   f[status][]   any of the model's statuses
#   f[from], f[to]  creation date range (inclusive days)
#   f[user][]     created by any of these users
#   f[receiver]   a receiving warehouse id, or "none" (not headed anywhere yet)
#   f[category]   items: a category id, or "none" (uncategorized)
#   f[instances]  items: "used" (packed somewhere) or "unused"
class ListFilter
  NONE = "none"
  INSTANCE_CHOICES = { "used" => "In use", "unused" => "Not used anywhere" }.freeze

  attr_reader :model, :available_statuses, :statuses, :from, :to, :user_ids, :receiver, :category, :instances

  # statuses: the statuses offered (pass [] to hide the status filter).
  def initialize(model, params, statuses: model.const_defined?(:STATUSES) ? model::STATUSES : [])
    @model = model
    @available_statuses = statuses
    f = params[:f].respond_to?(:permit) ? params[:f].permit(:from, :to, :receiver, :category, :instances, status: [], user: []) : {}

    @statuses = Array(f[:status]) & statuses
    @from = parse_date(f[:from])
    @to = parse_date(f[:to])
    @user_ids = Array(f[:user]).map(&:to_i).select(&:positive?)
    @receiver = choice(f[:receiver])
    @category = choice(f[:category])
    @instances = f[:instances] if INSTANCE_CHOICES.key?(f[:instances])
  end

  # Narrows `scope` by every filter that's set.
  def apply(scope)
    table = model.table_name
    scope = scope.where(table => { status: statuses }) if statuses.any?
    scope = scope.where(table => { created_at: from.beginning_of_day.. }) if from
    scope = scope.where(table => { created_at: ..to.end_of_day }) if to
    scope = scope.where(table => { user_id: user_ids }) if user_ids.any?
    scope = apply_receiver(scope)
    scope = apply_category(scope)
    apply_instances(scope)
  end

  def active?
    active_count.positive?
  end

  # How many separate filters are set (a date range counts once).
  def active_count
    [statuses.any?, from || to, user_ids.any?, receiver, category, instances].count(&:present?)
  end

  # People who have created at least one of these records, for "Created by".
  def user_choices
    User.where(id: model.select(:user_id)).order(:first_name, :last_name).pluck(:first_name, :last_name, :id)
      .map { |first, last, id| ["#{first} #{last}".strip, id] }
  end

  def receiver_choices
    Warehouse.order(:name).pluck(:name, :id)
  end

  def category_choices
    Category.order(:name).pluck(:name, :id)
  end

  private

  def apply_receiver(scope)
    return scope unless receiver && model.respond_to?(:received_by)

    headed = receiver == NONE ? model.received_by : model.received_by(receiver.to_i)
    receiver == NONE ? scope.where.not(id: headed.select(:id)) : scope.where(id: headed.select(:id))
  end

  def apply_category(scope)
    return scope unless category && model == Item

    scope.where(items: { category_id: category == NONE ? nil : category.to_i })
  end

  def apply_instances(scope)
    return scope unless instances && model == Item

    used = PackedItem.select(:item_id)
    instances == "used" ? scope.where(id: used) : scope.where.not(id: used)
  end

  # "none" or a positive id, as a string; anything else is ignored
  def choice(value)
    value = value.to_s
    return NONE if value == NONE

    value if value.match?(/\A[1-9]\d*\z/)
  end

  def parse_date(value)
    Date.iso8601(value.to_s)
  rescue Date::Error
    nil
  end
end
