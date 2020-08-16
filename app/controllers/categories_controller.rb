# frozen_string_literal: true

class CategoriesController < ApplicationController
  before_action :set_category, only: %i[show destroy edit update]

  def new
    @category = Category.new
  end

  def create
    Category.create(category_params.merge(user: current_user))
    redirect_to categories_path
  end

  def index
    @categories = Category.all.page params[:page]
  end

  def show
  end

  def edit
  end

  def update
    @category.update(category_params)
    redirect_to categories_path
  end

  def destroy
    @category.destroy
    redirect_to categories_path
  end

  private

  def category_params
    params.require(:category).permit(:name, :description)
  end

  def set_category
    @category = Category.find(params[:id])
  end
end
