# frozen_string_literal: true

class CategoriesController < ApplicationController
  before_action :set_category, only: %i[show destroy update]

  def new
    @category = Category.new
  end

  def create
    category = Category.new(category_params.merge(user: current_user))

    if category.save
      redirect_to category_path(category), flash: { success: "Category creation successful." }
    else
      redirect_to categories_path, flash: { error: "Failed to create new category: #{category.errors.full_messages.to_sentence}" }
    end
  end

  def index
    @categories = Category.all.page params[:page]
  end

  def show
  end

  def update
    if @category.update(category_params)
      redirect_to category_path(@category), flash: { success: "Category update successful." }
    else
      redirect_to category_path(@category), flash: { error: "Failed to update category: #{@category.errors.full_messages.to_sentence}" }
    end
  end

  def destroy
    @category.destroy
    redirect_to categories_path, flash: { success: "Category deletion successful." }
  end

  private

  def category_params
    params.require(:category).permit(:name, :description)
  end

  def set_category
    @category = Category.find(params[:id])
  end
end
