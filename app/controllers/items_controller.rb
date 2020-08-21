# frozen_string_literal: true

class ItemsController < ApplicationController
  before_action :set_item, only: %i[show destroy edit update]

  def new
    @item = Item.new
  end

  def create
    Item.create(item_params.merge(user: current_user))
    redirect_to params[:redirect]
  end

  def index
    @items = Item.all.page params[:page]
  end

  def search
    if params[:search]
      @search_results_items = Item.search_by_generated_name(params[:search]).where.not(id: params[:existing_item_ids].split(" "))
      respond_to do |format|
        format.js { render partial: "search-results", locals: { box: Box.find(params[:box_id]) } }
      end
    else
      @items = Item.all.page params[:page]
    end
  end

  def show
  end

  def update
    @item.update(item_params)
    redirect_to items_path
  end

  def destroy
  end

  private

  def item_params
    params.require(:item).permit(:brand, :object, :standardized_size, :concentration, :concentration_units, :concentration_description, :numerical_size_1, :numerical_units_1, :numerical_description_1, :numerical_size_2, :numerical_units_2, :numerical_description_2, :packaged_quantity, :category_id, :notes)
  end

  def set_item
    @item = Item.find(params[:id])
  end
end
