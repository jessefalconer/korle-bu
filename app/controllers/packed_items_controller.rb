# frozen_string_literal: true

class PackedItemsController < ApplicationController
  def index
    @boxes = Box.in_progress.order(:id).reverse_order
    @pallets = Pallet.in_progress.order(:id).reverse_order
    @containers = Container.in_progress.order(:id).reverse_order
    @packed_items = PackedItem.staged.order(:created_at).reverse_order.page params[:page]
  end
end
