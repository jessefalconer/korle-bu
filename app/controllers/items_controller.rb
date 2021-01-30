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
    @items = Item.all.order(:created_at).reverse_order.page params[:page]
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

    @search_results_items = Item.search_by_generated_name(params[:search])
    form_path, model = generate_form_url(params[:model], record)

    render json: render_to_string(partial: "results-form", layout: false, locals: { model: model, form_path: form_path }).to_json
  end

  def show
  end

  def update
    if @item.update(item_params)
      redirect_to item_path(@item), flash: { success: "Item updated." }
    else
      redirect_to item_path(@item), flash: { error: "Failed to update item: #{@item.errors.full_messages.to_sentence}" }
    end
  end

  def destroy
    @item.destroy
    redirect_to items_path, flash: { success: "Item deleted." }
  end

  private

  def destroy_photo
    @item.photo.destroy if params[:destroy_photo] && @item.photo.present?
  end

  def generate_form_url(klass, record)
    case klass
    when "Box"
      [box_box_items_path(record.id), :box_item]
    when "Pallet"
      [pallet_pallet_items_path(record.id), :pallet_item]
    when "Container"
      [container_container_items_path(record.id), :container_item]
    end
  end

  def item_params
    params.require(:item).permit(:brand, :object, :standardized_size, :concentration, :concentration_units, :concentration_description,
                                 :numerical_size_1, :numerical_units_1, :numerical_description_1, :numerical_size_2, :numerical_units_2, :numerical_description_2,
                                 :area_1, :area_2, :area_units, :area_description, :range_1, :range_2, :range_units, :range_description, :packaged_quantity,
                                 :category_id, :notes, :verified, :photo, :flagged)
  end

  def set_item
    @item = Item.find(params[:id])
  end
end
