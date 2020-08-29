# frozen_string_literal: true

class ReconcileItemsController < ApplicationController
  before_action :set_item, only: %i[start confirm execute item_instances]
  before_action :set_target_item, only: %i[confirm execute]

  def show
    @overview = ReconcileItem.new(current_user)
  end

  def start
    @overview = ReconcileItem.new(current_user)
    @items = @overview.find_similar_records(@item)
  end

  def confirm
    @overview = ReconcileItem.new(current_user)
  end

  def execute
    @overview = ReconcileItem.new(current_user)
    @overview.execute_merge(@item, @target_item, delete: params[:delete_item])

    redirect_to reconcile_overview_path
  end

  def item_instances
    @boxed_items = BoxedItem.where(item: @item).order(:created_at).reverse
    @palletized_items = PalletizedItem.where(item: @item).order(:created_at).reverse
    @containerized_items = ContainerizedItem.where(item: @item).order(:created_at).reverse
  end

  private

  def set_item
    @item = Item.find(params[:id])
  end

  def set_target_item
    @target_item = Item.find(params[:target_id])
  end
end
