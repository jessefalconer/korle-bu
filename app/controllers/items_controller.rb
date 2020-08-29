# frozen_string_literal: true

class ItemsController < ApplicationController
  before_action :set_item, only: %i[show destroy update]

  def new
    @item = Item.new
  end

  def create
    item = Item.new(item_params.merge(user: current_user))

    if item.save
      redirect_to item_path(item), flash: { success: "Item creation successful." }
    else
      redirect_to items_path, flash: { error: "Failed to create new item: #{item.errors.full_messages.to_sentence}" }
    end
  end

  def index
    @items = Item.all.page params[:page]
  end

  def search
    @search_results_items = Item.search_by_generated_name(params[:search]).where.not(id: params[:compare_id].to_i)
    respond_to do |format|
      format.js { render partial: "search-results", locals: { record: params[:compare_id] } }
    end
  end

  def search_form
    klass = params[:model].constantize
    record = klass.find(params[:id])
    existing_ids = record.items.ids

    @search_results_items = Item.search_by_generated_name(params[:search]).where.not(id: existing_ids)
    form_path = generate_form_url(params[:model], record)

    respond_to do |format|
      format.js { render partial: "search-results-form", locals: { record: record, form_path: form_path } }
    end
  end

  def show
  end

  def update
    if @item.update(item_params)
      redirect_to item_path(@item), flash: { success: "Item update successful." }
    else
      redirect_to item_path(@item), flash: { error: "Failed to update item: #{@item.errors.full_messages.to_sentence}" }
    end
    # @item.photo.attach(params[:photo])
    # @item.update(item_params)
    # redirect_to items_path
  end

  def destroy
    @item.destroy
    redirect_to items_path, flash: { success: "Item deletion successful." }
  end

  private

  def generate_form_url(klass, record)
    case klass
    when "Box"
      box_boxed_items_path(record.id)
    when "Pallet"
      pallet_palletized_items_path(record.id)
    when "Container"
      container_containerized_items_path(record.id)
    end
  end

  def item_params
    params.require(:item).permit(:brand, :object, :standardized_size, :concentration, :concentration_units, :concentration_description, :numerical_size_1, :numerical_units_1, :numerical_description_1, :numerical_size_2, :numerical_units_2, :numerical_description_2, :packaged_quantity, :category_id, :notes, :verified, :photo, :flagged)
  end

  def set_item
    @item = Item.find(params[:id])
  end
end
