# frozen_string_literal: true

class ReconcileItemsController < ApplicationController
  before_action :set_item, only: %i[start confirm execute item_instances]
  before_action :set_target_item, only: %i[confirm execute]

  def unverified
    @items = Item.unverified.order(:updated_at).reverse_order.page params[:page]
  end

  def uncategorized
    @items = Item.uncategorized.order(:updated_at).reverse_order.page params[:page]
  end

  def flagged
    @items = Item.flagged.order(:updated_at).reverse_order.page params[:page]
  end

  def start
    @overview = ReconcileItem.new(current_user)
    @similar_items = @overview.find_similar_records(@item)
  end

  def confirm
    @overview = ReconcileItem.new(current_user)
  end

  def execute
    @overview = ReconcileItem.new(current_user)
    @overview.execute_merge(@item, @target_item, delete: params[:delete_item], verify: params[:verify_item])

    redirect_to reconcile_unverified_path
  end

  def item_instances
    items = PackedItem.where(item: @item)
    @staged_items = items.staged.order(:created_at).reverse_order
    @box_items = items.where.not(box_id: nil).order(:created_at).reverse_order
    @pallet_items = items.where.not(pallet_id: nil).order(:created_at).reverse_order
    @container_items = items.where.not(container_id: nil).order(:created_at).reverse_order
  end

  private

  def set_item
    @item = Item.find(params[:id])
  end

  def set_target_item
    @target_item = Item.find(params[:target_id])
  end
end
