# frozen_string_literal: true

class PackedItemsController < ApplicationController
  include BulkUnpacking

  # Received-inventory pages and unpacking: for those who log unpacking events.
  before_action { authorize! :create, UnpackingEvent }
  before_action :set_warehouse_id

  def all_received_items
    received = PackedItem.received_in(@warehouse_id).where.not(items: { category_id: nil })
    per_page = Kaminari.config.default_per_page

    # Paginate distinct items in SQL, then load packed items only for this page.
    items = Item.where(id: received.select(:item_id))
      .preload(:category)
      .order(:generated_name, :id)
      .page(params[:page]).per(per_page)
    packed_by_item = received.where(item_id: items.map(&:id)).with_parents.group_by(&:item_id)
    pairs = items.map { |item| [item, packed_by_item.fetch(item.id, [])] }

    @items = Kaminari.paginate_array(pairs, total_count: items.total_count).page(params[:page]).per(per_page)
  end

  def received_categories
    received = PackedItem.received_in(@warehouse_id)
    totals_sql = Arel.sql("COUNT(DISTINCT packed_items.item_id), SUM(packed_items.remaining_quantity)")

    totals_by_category = received.where.not(items: { category_id: nil })
      .group("items.category_id")
      .pluck(Arel.sql("items.category_id"), totals_sql)
      .to_h { |category_id, item_count, remaining| [category_id, { item_count: item_count, remaining: remaining.to_i }] }
    @category_totals = Category.where(id: totals_by_category.keys).order(:name)
      .map { |category| [category, totals_by_category[category.id]] }

    item_count, remaining = received.where(items: { category_id: nil }).pick(totals_sql)
    @uncategorized_totals = { item_count: item_count.to_i, remaining: remaining.to_i }
  end

  def received_category_items
    @category = Category.find(params.expect(:id))
    @packed_items = PackedItem.received_in(@warehouse_id)
      .where(items: { category_id: params[:id] })
      .preload(:item)
      .order("items.generated_name")
      .page params[:page]
  end

  def received_uncategorized_items
    @packed_items = PackedItem.received_in(@warehouse_id)
      .where(items: { category_id: nil })
      .preload(:item)
      .order("items.generated_name")
      .page params[:page]

    render "received_category_items"
  end

  def received_item_locations
    @item = Item.find(params.expect(:id))
    received = PackedItem.received_in(@warehouse_id).where(item_id: params[:id])

    @box_items = received.where.not(box_id: nil).preload(:box)
    @pallet_items = received.where.not(pallet_id: nil).preload(:pallet)
    @container_items = received.where.not(container_id: nil).preload(:container)
  end

  def unpack_selected
    message = if params[:item_ids].blank?
      { error: "Select at least one item to unpack." }
    else
      unpack_everything(PackedItem.where(id: params[:item_ids]))
    end

    redirect_back_or_to(all_received_items_path, flash: message)
  end

  private

  def set_warehouse_id
    @warehouse_id = current_user.warehouse_id
  end
end
