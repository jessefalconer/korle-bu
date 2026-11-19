# frozen_string_literal: true

class ItemsController < ApplicationController
  load_and_authorize_resource only: %i[create update destroy]
  before_action :set_item, only: %i[show destroy update]

  def new
    @item = Item.new
  end

  def create
    item = Item.new(item_params.merge(user: current_user))

    if item.save
      redirect_to item_path(item),
                  flash: { success: "Item created: #{item.generated_name}." }
    else
      redirect_to items_path,
                  flash: { error: "Failed to create new item: #{item.errors.full_messages.to_sentence}" }
    end
  end

  def index
    @items = if params[:category]
      Item.includes(:category).where(category_id: params[:category])
        .order(:generated_name)
        .page params[:page]
    elsif params[:search_string]
      Item.includes(:category).search_by_generated_name(params[:search_string])
        .page params[:page]
    else
      Item.includes(:category).all.order(:generated_name).page params[:page]
    end
  end

  def index_search
    @items = Item.search_by_generated_name(params[:search])

    render json: render_to_string(
      partial: "table",
      layout: false,
      locals: { comparison_item: params[:search] }
    ).to_json
  end

  def unverified_search
    @items = Item.unverified.search_by_generated_name(params[:search])

    render json: render_to_string(
      partial: "reconcile_items/unverified_table",
      layout: false,
      locals: { comparison_item: params[:search] }
    ).to_json
  end

  def uncategorized_search
    @items = Item.uncategorized.search_by_generated_name(params[:search])

    render json: render_to_string(
      partial: "reconcile_items/uncategorized_table",
      layout: false,
      locals: { comparison_item: params[:search] }
    ).to_json
  end

  def reconcile_search
    excluded_ids = params[:similar_ids] || []
    excluded_ids << params[:compare_id]
    @search_results_items = Item.search_by_generated_name(params[:search])
      .where
      .not(id: excluded_ids)
    @item = Item.find(params[:compare_id])

    render json: render_to_string(
      partial: "results_reconcile",
      layout: false,
      locals: { comparison_item: params[:search] }
    ).to_json
  end

  def search_form
    @search_results_items = Item.search_by_generated_name(params[:search])
      .limit(25)
      .pluck(:id, :generated_name)
    form_path = generate_form_url(params[:model], params[:id])

    render json: render_to_string(
      partial: "results_form",
      layout: false,
      locals: { form_path: form_path, status: params[:status] }
    ).to_json
  end

  def packed_search
    search_results_item_ids = Item.search_by_generated_name(params[:search])
      .limit(25)
      .pluck(:id)
    @items = PackedItem.received_in(current_user.warehouse_id)
      .where.not(items: { category_id: nil })
      .where(item_id: search_results_item_ids)
      .preload(item: :category)
      .with_parents
      .group_by(&:item)
      .sort_by { |item, _items| item.generated_name }

    render json: render_to_string(
      partial: "packed_items/nested_unpack_form_card",
      layout: false,
      locals: { items: @items }
    ).to_json
  end

  def show
  end

  def update
    path = if (list_path = reconcile_list_redirect)
      list_path
    elsif params[:redirect] == "reconcile_start_path"
      reconcile_start_path(@item)
    else
      item_path(@item)
    end

    if @item.update(item_params)
      redirect_to path, flash: { success: "Item updated." }
    else
      redirect_to path,
                  flash: { error: "Failed to update item: #{@item.errors.full_messages.to_sentence}" }
    end
  end

  def destroy
    path = if (list_path = reconcile_list_redirect)
      list_path
    else
      items_path
    end

    @item.destroy
    redirect_to path, flash: { success: "Item deleted." }
  end

  private

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

  # Forms on the reconcile lists send the list's route name so the user lands
  # back on it. Map the few allowed names to paths; anything else is ignored.
  def reconcile_list_redirect
    case params[:redirect]
    when "reconcile_unverified_path" then reconcile_unverified_path
    when "reconcile_uncategorized_path" then reconcile_uncategorized_path
    when "reconcile_flagged_path" then reconcile_flagged_path
    end
  end

  def item_params
    params.require(:item).permit(
      :brand, :object, :standardized_size,
      :numerical_size_1, :numerical_units_1, :numerical_description_1,
      :numerical_size_2, :numerical_units_2, :numerical_description_2,
      :area_1, :area_2, :area_units, :area_description,
      :range_1, :range_2, :range_units, :range_description, :unit_weight,
      :category_id, :notes, :verified, :flagged
    )
  end

  def set_item
    @item = Item.find(params[:id])
  end
end
