# frozen_string_literal: true

class ItemsController < ApplicationController
  def new
  end

  def create
    Item.create(item_params.merge(user: current_user))
    redirect_to params[:redirect]
  end

  def index
  end

  def list
    @items = Item.all
  end

  def search
    if params[:search]
      @search_results_items = Item.search_by_generated_name(params[:search]).where.not(id: params[:existing_item_ids].split(" "))
      respond_to do |format|
        format.js { render partial: "search-results", locals: { box: Box.find(params[:box_id]) } }
      end
    else
      @items = Item.all
    end
  end

  def show
  end

  def update
  end

  def destroy
  end

  private

  def item_params
    params.require(:item).permit(:brand, :object, :standardized_size, :concentration, :concentration_units, :concentration_description, :numerical_size_1, :numerical_units_1, :numerical_description_1, :numerical_size_2, :numerical_units_2, :numerical_description_2, :packaged_quantity, :category_id, :notes)
  end
end
