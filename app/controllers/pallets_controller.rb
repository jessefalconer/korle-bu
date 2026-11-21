# frozen_string_literal: true

class PalletsController < ApplicationController
  include BulkUnpacking

  load_and_authorize_resource
  include ConfirmsDeletion

  before_action :set_pallet, only: %i[show destroy update]

  def index
    scope = display_scope(%w[staged in_progress warehoused])
    # The staged / in-progress / warehoused pages are already a status view
    @filter = ListFilter.new(Pallet, params, statuses: scope ? [] : Pallet::STATUSES)
    pallets = Pallet.with_location.accessible_by(current_ability)
    pallets = if scope
      pallets.public_send(scope)
    elsif @filter.statuses.empty?
      # Staged and Warehoused have their own menus, unless asked for here
      pallets.where.not(status: %w[Warehoused Staged])
    else
      pallets
    end
    @pallets = @filter.apply(pallets).order(custom_uid: :desc).page params[:page]

    @box_options = Box.reassignable
      .order(id: :desc)
      .pluck(:name, :id)
    @pallet_options = Pallet.reassignable
      .order(id: :desc)
      .pluck(:name, :id)
    @container_options = Container.in_progress
      .order(id: :desc)
      .pluck(:name, :id)
  end

  def show
    @staged_items = PackedItem.staged
      .preload(:item)
      .order(created_at: :desc)
    @staged_boxes = Box.staged
      .with_location
      .order(custom_uid: :desc)
    @warehoused_items = PackedItem.warehoused
      .preload(:item)
      .order(created_at: :desc)
    @warehoused_boxes = Box.warehoused
      .with_location
      .order(custom_uid: :desc)
    @box_options = Box.reassignable
      .order(id: :desc)
      .pluck(:name, :id)
    @pallet_options = Pallet.reassignable
      .order(id: :desc)
      .pluck(:name, :id)
    @container_options = Container.in_progress
      .order(id: :desc)
      .pluck(:name, :id)
  end

  def new
    @pallet = Pallet.new(container_id: params[:container_id])
  end

  def create
    pallet = Pallet.new(pallet_params.merge(user: current_user))

    if pallet.save
      redirect_to pallet_path(pallet), flash: { success: "Pallet created." }
    else
      redirect_to pallets_path,
                  flash: { error: "Failed to create new pallet: #{pallet.errors.full_messages.to_sentence}" }
    end
  end

  def update
    if @pallet.update(pallet_params)
      redirect_to pallet_path(@pallet), flash: { success: "Pallet updated." }
    else
      redirect_to pallet_path(@pallet),
                  flash: { error: "Failed to update pallet: #{@pallet.errors.full_messages.to_sentence}" }
    end
  end

  def destroy
    @pallet.destroy
    redirect_to pallets_path, flash: { success: "Pallet deleted." }
  end

  def find
    pallet = Pallet.accessible_by(current_ability)
      .find_by(custom_uid: pallet_params[:custom_uid])

    if pallet
      path = params[:button] == "info" ? pallet_path(pallet) : pallet_pallet_items_path(pallet)
      redirect_to path
    else
      redirect_to return_path(pallets_path),
                  flash: { error: "Pallet with custom ID #{pallet_params[:custom_uid]} not found." }
    end
  end

  def unpack_all
    redirect_back_or_to(pallet_pallet_items_path(@pallet), flash: unpack_everything(@pallet.pallet_items))
  end

  private

  def pallet_params
    params
      .expect(
        pallet: %i[name status notes custom_uid
                   container_id category_id weight]
      )
  end

  def set_pallet
    @pallet = Pallet.preload(
      :boxes, :category, :user,
      pallet_items: :item, box_items: :item,
      container: { shipment: :receiving_warehouse }
    ).find(params.expect(:id))
  end
end
