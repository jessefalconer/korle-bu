# frozen_string_literal: true

class DashboardStats
  # A receiving manager's view: stock still to unpack in their warehouse and
  # where it has gone. Shares the period, caching and comparison helpers.
  class Receiving < DashboardStats
    STALE_AFTER = 60.days
    EXPIRY_WINDOW = 90.days

    def received_tiles
      cached("received_tiles", per_warehouse: true) do
        lines, distinct_items, remaining, weight = received.pick(
          Arel.sql("COUNT(*), COUNT(DISTINCT packed_items.item_id), COALESCE(SUM(packed_items.remaining_quantity), 0), " \
                   "COALESCE(SUM(packed_items.weight * packed_items.remaining_quantity / NULLIF(packed_items.quantity, 0)), 0)")
        )
        {
          lines: lines.to_i, distinct_items: distinct_items.to_i, remaining: remaining.to_i, weight: weight.to_f.round,
          earliest_expiry: received.where(expiry_date: Date.current..).minimum(:expiry_date),
          expired: received.where(expiry_date: ...Date.current).count
        }
      end
    end

    def stock_by_category
      cached("stock_categories", per_warehouse: true) do
        rows = received
          .joins("LEFT JOIN categories ON categories.id = items.category_id")
          .group(Arel.sql("COALESCE(categories.name, 'Uncategorized')"))
          .order(Arel.sql("SUM(packed_items.remaining_quantity) DESC"))
          .sum(:remaining_quantity)
          .to_a
        top = rows.first(7)
        rest = rows.drop(7).sum { |_name, units| units }
        rest.positive? ? top + [["Other", rest]] : top
      end
    end

    # Not cached: these are records the page links to.
    def expiring_soon
      received.where(expiry_date: Date.current..EXPIRY_WINDOW.from_now.to_date)
        .order(:expiry_date)
        .preload(:item)
        .with_parents
        .limit(10)
    end

    def expiring_soon_count
      received.where(expiry_date: Date.current..EXPIRY_WINDOW.from_now.to_date).count
    end

    # In stock, but nothing has been unpacked from it (or the item changed) lately.
    def stale_stock
      received.where(packed_items: { updated_at: ...STALE_AFTER.ago })
        .where.not(id: UnpackingEvent.where(timestamp: STALE_AFTER.ago..).select(:packed_item_id))
    end

    private

    def received
      PackedItem.received_in(user.warehouse_id)
    end
  end
end
