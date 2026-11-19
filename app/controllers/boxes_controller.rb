# frozen_string_literal: true

class BoxesController < ApplicationController
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
      redirect_to params[:redirect],
                  flash: { error: "Box with custom ID #{box_params[:custom_uid]} not found." }
    end
  end

  def unpack_all
    # Definitely move this to a service :/
    if params[:hospital_id].blank?
      message = { error: "Please select a hospital/facility/clinic." }
    else
      @box.box_items.each do |bi|
        next if bi.remaining_quantity.zero?

        bi.unpacking_events
          .create(
            hospital_id: params[:hospital_id],
            notes: params[:notes],
            user: current_user,
            timestamp: params[:timestamp],
            quantity: bi.remaining_quantity
          )
      end

      message = { success: "#{@box.box_items.count} item(s) unpacked." }
    end

    redirect_back_or_to(request.referer, flash: message)
  end

  def duplicate
    box = Box.find(params.expect(:box_id))
    deep_clone = params[:strategy] == "deep"
    pallet_id = box.pallet_id if deep_clone
    container_id = box.container_id if deep_clone

    ActiveRecord::Base.transaction do
      params[:duplication_count].to_i.times do
        new_box = Box.create(
          status: box.status,
          weight: box.weight,
          user_id: box.user_id,
          notes: box.notes,
          pallet_id: pallet_id,
          container_id: container_id
        )
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

    redirect_back_or_to(request.referer, flash: { success: "#{box.name} duplicated #{params[:duplication_count]} times." })
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
