# frozen_string_literal: true

class SessionsController < ApplicationController
  skip_before_action :authorized, only: %i[new create]
  before_action :existing_session, only: %i[new create]

  def new
  end

  def create
    @user = User.find_by(email: params[:email])
    if @user&.authenticate(params[:password])
      session[:user_id] = @user.id
      if @user.status == "Deactivated"
        redirect_to login_path, flash: { success: "Your account has been created, however an administrator must approve it. Please check back later." }
        session.clear
      else
        redirect_to index_path, flash: { success: "Successfully logged in." }
      end
    else
      redirect_to login_path, flash: { error: "Email or password incorrect." }
    end
  end

  def destroy
    session.clear
    redirect_to login_path, flash: { success: "Successfully logged out." }
  end

  def login
  end

  def index
    @random_achievement = User.where.not(achiever_name: nil, achievement_title: nil, achievement_description: nil, achievement_value: nil, achievement_max_value: nil).sample

    @king_items = User.joins(:items).group("users.id").where("items.created_at >= ?", 30.days.ago).order("count(items.id) desc").limit(1).first || User.first
    @king_items_count = @king_items.items.where("items.created_at >= ?", 30.days.ago).count
    @items_total = Item.where("items.created_at >= ?", 30.days.ago).count

    @king_packed = User.joins(:packed_items).group("users.id").where("packed_items.created_at >= ?", 30.days.ago).order("count(packed_items.id) desc").limit(1).first || User.first
    @king_packed_count = @king_packed.packed_items.where("packed_items.created_at >= ?", 30.days.ago).count
    @packed_total = PackedItem.where("packed_items.created_at >= ?", 30.days.ago).count

    @king_verified = User.joins(:items).group("users.id").where("items.created_at >= ? AND items.verified = ?", 30.days.ago, true).order("count(items.id) desc").limit(1).first || User.first
    @king_verified_count = @king_verified.items.where("items.created_at >= ? AND items.verified = ?", 30.days.ago, true).count
    @verified_total = Item.where("items.created_at >= ? AND items.verified = ?", 30.days.ago, true).count

    @king_uncategorized = User.joins(:items).group("users.id").where("items.created_at >= ? AND items.category IS NULL", 30.days.ago).order("count(items.id) desc").limit(1).first || User.first
    @king_uncategorized_count = @king_uncategorized.items.where("items.created_at >= ? AND items.category IS NULL", 30.days.ago).count
    @uncategorized_total = Item.where("items.created_at >= ? AND items.category IS NULL", 30.days.ago).count

    @heaviest_item = PackedItem.where("packed_items.created_at >= ?", 30.days.ago).order("packed_items.weight desc NULLS LAST").limit(1).first
    @quantity_item = PackedItem.where("packed_items.created_at >= ?", 30.days.ago).order("packed_items.quantity desc").limit(1).first

    return unless current_user.receiving_manager?

    @packed_items = PackedItem.accessible_by(current_ability)
  end

  def my_activity
    @staged_items = PackedItem.staged.where("packed_items.created_at > ? AND user_id = ?", 30.days.ago, current_user.id).order(:updated_at).reverse_order
    @warehoused_items = PackedItem.warehoused.where("packed_items.created_at > ? AND user_id = ?", 30.days.ago, current_user.id).order(:updated_at).reverse_order
    @boxes = current_user.boxes.where("boxes.created_at > ?", 30.days.ago).order(:updated_at).reverse_order
    @box_items = current_user.box_items.where("packed_items.created_at > ?", 30.days.ago).order(:updated_at).reverse_order
    @pallets = current_user.pallets.where("pallets.created_at > ?", 30.days.ago).order(:updated_at).reverse_order
    @pallet_items = current_user.pallet_items.where("packed_items.created_at > ?", 30.days.ago).order(:updated_at).reverse_order
    @containers = current_user.containers.where("containers.created_at > ?", 30.days.ago).order(:updated_at).reverse_order
    @container_items = current_user.container_items.where("packed_items.created_at > ?", 30.days.ago).order(:updated_at).reverse_order
  end

  private

  def existing_session
    redirect_to index_path if logged_in?
  end
end
