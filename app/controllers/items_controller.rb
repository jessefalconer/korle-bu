# frozen_string_literal: true

class ItemsController < ApplicationController
  load_and_authorize_resource only: %i[create update destroy]
  before_action :set_item, only: %i[show destroy update]
  after_action :destroy_photo, only: :update

  def new
    @item = Item.new
  end

  def create
    item = Item.new(item_params.merge(user: current_user))

    if item.save
      redirect_to item_path(item), flash: { success: "Item created: #{item.generated_name}." }
    else
      redirect_to items_path, flash: { error: "Failed to create new item: #{item.errors.full_messages.to_sentence}" }
    end
  end

  def index
    @items = if params[:category]
      Item.where(category_id: params[:category]).order(:generated_name).page params[:page]
    elsif params[:search_string]
      Item.search_by_generated_name(params[:search_string]).page params[:page]
    else
      Item.all.order(:generated_name).page params[:page]
    end
  end

  def index_search
    @items = Item.search_by_generated_name(params[:search])

    render json: render_to_string(partial: "table", layout: false, locals: { comparison_item: params[:search] }).to_json
  end

  def unverified_search
    @items = Item.unverified.search_by_generated_name(params[:search])

    render json: render_to_string(partial: "reconcile_items/unverified_table", layout: false, locals: { comparison_item: params[:search] }).to_json
  end

  def uncategorized_search
    @items = Item.uncategorized.search_by_generated_name(params[:search])

    render json: render_to_string(partial: "reconcile_items/uncategorized_table", layout: false, locals: { comparison_item: params[:search] }).to_json
  end

  def reconcile_search
    excluded_ids = params[:similar_ids] || []
    excluded_ids << params[:compare_id]
    @search_results_items = Item.search_by_generated_name(params[:search]).where.not(id: excluded_ids)
    @item = Item.find(params[:compare_id])

    render json: render_to_string(partial: "results_reconcile", layout: false, locals: { comparison_item: params[:search] }).to_json
  end

  def search_form
    @search_results_items = Item.search_by_generated_name(params[:search]).limit(25).pluck(:id, :generated_name)
    form_path = generate_form_url(params[:model], params[:id])

    render json: render_to_string(partial: "results_form", layout: false, locals: { form_path: form_path, status: params[:status] }).to_json
  end

  def packed_search
    search_results_item_ids = Item.search_by_generated_name(params[:search]).limit(25).pluck(:id)
    @items = PackedItem.left_joins(:item, :shipment)
                               .where("items.category_id IS NOT NULL AND
                                packed_items.remaining_quantity > 0 AND
                                packed_items.status <> ? AND
                                shipments.receiving_warehouse_id = ? AND
                                shipments.status = ? AND
                                packed_items.item_id IN (?)",
                                PackedItem::ARCHIVED, current_user.warehouse_id, Shipment::RECEIVED, search_results_item_ids)
                               .group_by(&:item)
                               .sort_by { |item, _items| item.generated_name }

    render json: render_to_string(partial: "packed_items/nested_unpack_form_card", layout: false, locals: { items: @items }).to_json
  end

  def show
  end

  def update
    path = if permitted_redirect
      eval(params[:redirect]) # rubocop:disable Security/Eval
    elsif params[:redirect] == "reconcile_start_path"
      reconcile_start_path(@item)
    else
      item_path(@item)
    end

    if @item.update(item_params)
      redirect_to path, flash: { success: "Item updated." }
    else
      redirect_to path, flash: { error: "Failed to update item: #{@item.errors.full_messages.to_sentence}" }
    end
  end

  def destroy
    path = if permitted_redirect
      eval(params[:redirect]) # rubocop:disable Security/Eval
    else
      items_path
    end

    @item.destroy
    redirect_to path, flash: { success: "Item deleted." }
  end

  private

  def destroy_photo
    @item.photo.destroy if params[:destroy_photo] && @item.photo.present?
  end

  def generate_form_url(klass, id)
    case klass
    when "Box"
      box_box_items_path(id)
    when "Pallet"
      pallet_pallet_items_path(id)
    when "Container"
      container_container_items_path(id)
    when "Staged"
      staged_items_path
    when "Warehoused"
      warehoused_items_path
    end
  end

  def permitted_redirect
    %w[reconcile_unverified_path reconcile_uncategorized_path reconcile_flagged_path].include? params[:redirect]
  end

  def item_params
    params.require(:item).permit(:brand, :object, :standardized_size,
                                 :numerical_size_1, :numerical_units_1, :numerical_description_1, :numerical_size_2, :numerical_units_2, :numerical_description_2,
                                 :area_1, :area_2, :area_units, :area_description, :range_1, :range_2, :range_units, :range_description, :unit_weight,
                                 :category_id, :notes, :verified, :photo, :flagged)
  end

  def set_item
    @item = Item.find(params[:id])
  end
end
