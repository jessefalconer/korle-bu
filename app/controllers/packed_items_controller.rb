# frozen_string_literal: true

class PackedItemsController < ApplicationController
  # @todo refactor these to use accessible_by(current_ability)
  before_action :set_warehouse_id

  def all_received_items
    @items = PackedItem.left_joins(:item, :shipment)
                       .where("items.category_id IS NOT NULL AND
                        packed_items.remaining_quantity > 0 AND
                        packed_items.status <> ? AND
                        shipments.receiving_warehouse_id = ? AND
                        shipments.status = ?",
                              PackedItem::ARCHIVED, @warehouse_id, Shipment::RECEIVED)
                       .group_by(&:item)
                       .sort_by { |item, _items| item.generated_name }

    @items = Kaminari.paginate_array(@items).page(params[:page])
  end

  def received_categories
    @packed_items = PackedItem.left_joins(:item, :shipment)
                               .where("items.category_id IS NOT NULL AND
                                packed_items.remaining_quantity > 0  AND
                                packed_items.status <> ? AND
                                shipments.receiving_warehouse_id = ? AND
                                shipments.status = ?",
                                      PackedItem::ARCHIVED, @warehouse_id, Shipment::RECEIVED)
                               .group_by(&:category)
                               .sort_by { |category, _items| category.name }

    @uncategorized_items = PackedItem.left_joins(:item, :shipment)
                                     .where("items.category_id IS NULL AND
                                      packed_items.remaining_quantity > 0 AND
                                      packed_items.status <> ? AND
                                      shipments.receiving_warehouse_id = ? AND
                                      shipments.status = ?",
                                            PackedItem::ARCHIVED, @warehouse_id, Shipment::RECEIVED)
  end

  def received_category_items
    @category = Category.find(params[:id])
    @packed_items = PackedItem.left_joins(:item, :shipment)
                               .where("items.category_id = ? AND
                                packed_items.remaining_quantity > 0 AND
                                packed_items.status <> ? AND
                                shipments.receiving_warehouse_id = ? AND
                                shipments.status = ?",
                                      params[:id], PackedItem::ARCHIVED, @warehouse_id, Shipment::RECEIVED)
                               .order("items.generated_name")
                               .page params[:page]
  end

  def received_uncategorized_items
    @packed_items = PackedItem.left_joins(:item, :shipment)
                               .where("items.category_id IS NULL AND
                                packed_items.remaining_quantity > 0 AND
                                packed_items.status <> ? AND
                                shipments.receiving_warehouse_id = ? AND
                                shipments.status = ?",
                                      PackedItem::ARCHIVED, @warehouse_id, Shipment::RECEIVED)
                               .order("items.generated_name")
                               .page params[:page]

    render "received_category_items"
  end

  def received_item_locations
    @item = Item.find(params[:id])

    @box_items = PackedItem.left_joins(:item, :shipment)
                           .where("packed_items.box_id IS NOT NULL AND
                            packed_items.item_id = ? AND
                            packed_items.remaining_quantity > 0 AND
                            packed_items.status <> ? AND
                            shipments.receiving_warehouse_id = ? AND
                            shipments.status = ?",
                                  params[:id], PackedItem::ARCHIVED, @warehouse_id, Shipment::RECEIVED)

    @pallet_items = PackedItem.left_joins(:item, :shipment)
                              .where("packed_items.pallet_id IS NOT NULL AND
                                packed_items.item_id = ? AND
                                packed_items.remaining_quantity > 0 AND
                                packed_items.status <> ? AND
                                shipments.receiving_warehouse_id = ? AND shipments.status = ?",
                                     params[:id], PackedItem::ARCHIVED, @warehouse_id, Shipment::RECEIVED)
    @container_items = PackedItem.left_joins(:item, :shipment)
                                 .where("packed_items.container_id IS NOT NULL AND
                                  packed_items.item_id = ? AND
                                  packed_items.remaining_quantity > 0 AND
                                  packed_items.status <> ? AND
                                  shipments.receiving_warehouse_id = ? AND
                                  shipments.status = ?",
                                        params[:id], PackedItem::ARCHIVED, @warehouse_id, Shipment::RECEIVED)
  end

  def unpack_selected
    # Definitely move this to a service :/
    if params[:hospital_id].blank?
      message = { error: "Please select a hospital/facility/clinic." }
    else
      PackedItem.where(id: params[:item_ids]).find_each do |pi|
        pi.unpacking_events
          .create(
            hospital_id: params[:hospital_id],
            notes: params[:notes],
            user: current_user,
            quantity: pi.remaining_quantity
          )
      end

      message = { success: "#{params[:item_ids].count} item(s) unpacked." }
    end

    redirect_back fallback_location: request.referer, flash: message
  end

  private

  def set_warehouse_id
    @warehouse_id = current_user.warehouse_id
  end
end
