# frozen_string_literal: true

class ReconcileItemsController < ApplicationController
  before_action :set_item, only: %i[start confirm item_instances execute]

  def unverified
    @items = Item.unverified.order(:generated_name).page params[:page]
  end

  def uncategorized
    @items = Item.uncategorized.order(:generated_name).page params[:page]
  end

  def flagged
    @items = Item.flagged.order(:generated_name).page params[:page]
  end

  def start
    @similar_items = Item.find_similar_records(@item)
  end

  def confirm
    if params[:reconcile_ids].nil?
      redirect_to reconcile_start_path(@item),
        flash: { error: "No items where selected." }
    else
      @merge_items = Item.where(id: params[:reconcile_ids]).where.not(id: @item.id)
    end
  end

  def execute
    merge_items = Item.where(id: params[:confirmed_reconcile_ids])
    Item.execute_merge(
      @item,
      merge_items,
      delete: params[:delete_item],
      verify: params[:verify_item]
    )

    redirect_to reconcile_unverified_path
  end

  def item_instances
    items = @item.packed_items
    @staged_items = items.staged
      .order(created_at: :desc)
    @warehoused_items = items.warehoused
      .order(created_at: :desc)
    @box_items = items.where.not(box_id: nil)
      .order(created_at: :desc)r
    @pallet_items = items.where.not(pallet_id: nil)
      .order(created_at: :desc)
    @container_items = items.where.not(container_id: nil)
      .order(created_at: :desc)
  end

  private

  def set_item
    @item = Item.find(params[:id])
  end
end
