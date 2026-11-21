# frozen_string_literal: true

class CategoriesController < ApplicationController
  load_and_authorize_resource
  include ConfirmsDeletion

  before_action :set_category, only: %i[show destroy update]

  def index
    @categories = Category.order(:name).page params[:page]
  end

  def show
  end

  def new
    @category = Category.new
  end

  def create
    category = Category.new(category_params.merge(user: current_user))

    if category.save
      redirect_to category_path(category), flash: { success: "Category created." }
    else
      redirect_to categories_path,
                  flash: { error: "Failed to create new category: #{category.errors.full_messages.to_sentence}" }
    end
  end

  def update
    if @category.update(category_params)
      redirect_to category_path(@category), flash: { success: "Category updated." }
    else
      redirect_to category_path(@category),
                  flash: { error: "Failed to update category: #{@category.errors.full_messages.to_sentence}" }
    end
  end

  def destroy
    @category.destroy
    redirect_to categories_path, flash: { success: "Category deleted." }
  end

  private

  def category_params
    params.expect(category: %i[name description])
  end

  def set_category
    @category = Category.find(params.expect(:id))
  end
end
