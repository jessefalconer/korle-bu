# frozen_string_literal: true

class BoxesController < ApplicationController
  include BulkUnpacking
  include PlacementAuthorization

  load_and_authorize_resource
  before_action :set_box, only: %i[show destroy update]

  def index
    @boxes = if (scope = display_scope(%w[staged in_progress warehoused]))
      Box.with_location
        .accessible_by(current_ability)
        .public_send(scope)
        .order(custom_uid: :desc)
        .page params[:page]
    else
      Box.with_location
        .where.not(status: %w[Warehoused Staged])
        .accessible_by(current_ability)
        .order(custom_uid: :desc)
        .page params[:page]
    end

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
    @warehoused_items = PackedItem.warehoused
      .preload(:item)
      .order(created_at: :desc)
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
    @box = Box.new(
      container_id: params[:container_id],
      pallet_id: params[:pallet_id]
    )
  end

  def create
    box = Box.new(box_params.merge(user: current_user))

    if box.save
      redirect_to box_path(box), flash: { success: "Box created." }
    else
      redirect_to boxes_path,
                  flash: { error: "Failed to create new box: #{box.errors.full_messages.to_sentence}" }
    end
  end

  def update
    if @box.update(box_params)
      redirect_to box_path(@box), flash: { success: "Box updated." }
    else
      redirect_to box_path(@box),
                  flash: { error: "Failed to update box: #{@box.errors.full_messages.to_sentence}" }
    end
  end

  def destroy
    @box.destroy
    redirect_to boxes_path, flash: { success: "Box deleted." }
  end

  def find
    box = Box.accessible_by(current_ability)
      .find_by(custom_uid: box_params[:custom_uid])

    if box
      path = params[:button] == "info" ? box_path(box) : box_box_items_path(box)
      redirect_to path
    else
      redirect_to return_path(boxes_path),
                  flash: { error: "Box with custom ID #{box_params[:custom_uid]} not found." }
    end
  end

  def unpack_all
    redirect_back_or_to(box_box_items_path(@box), flash: unpack_everything(@box.box_items))
  end

  MAX_DUPLICATES = 10

  def duplicate
    box = Box.find(params.expect(:box_id))
    count = params[:duplication_count].to_i
    unless count.between?(1, MAX_DUPLICATES)
      return redirect_back_or_to(box_path(box), flash: { error: "Duplicate between 1 and #{MAX_DUPLICATES} copies at a time." })
    end

    authorize! :read, box
    deep_clone = params[:strategy] == "deep"
    pallet_id = box.pallet_id if deep_clone
    container_id = box.container_id if deep_clone

    ActiveRecord::Base.transaction do
      count.times do
        new_box = Box.new(
          status: box.status,
          weight: box.weight,
          user_id: box.user_id,
          notes: box.notes,
          pallet_id: pallet_id,
          container_id: container_id
        )
        # Copies keep the source's status and (if deep) location, so check both.
        authorize_placement!(:create, new_box)
        new_box.save
        box.box_items.each do |bi|
          new_box.box_items.create(
            quantity: bi.quantity,
            remaining_quantity: bi.remaining_quantity,
            weight: bi.weight,
            expiry_date: bi.expiry_date,
            shipment_id: (bi.shipment_id if deep_clone),
            item_id: bi.item_id,
            user_id: bi.user_id,
            show_id: bi.show_id,
            status: bi.status
          )
        end
      end
    end

    redirect_back_or_to(box_path(box), flash: { success: "#{box.name} duplicated #{count} #{"time".pluralize(count)}." })
  end

  private

  def box_params
    params
      .expect(
        box: %i[name status notes custom_uid
                pallet_id container_id weight]
      )
  end

  def set_box
    @box = Box.with_location.preload(:user, box_items: :item).find(params.expect(:id))
  end
end
