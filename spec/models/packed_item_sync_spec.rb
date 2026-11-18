# frozen_string_literal: true

require "rails_helper"

describe "PackedItem.sync_with_parents!" do
  let(:shipment) { create :shipment }
  let(:container) { create :container, shipment: shipment }
  let(:pallet) { create :pallet, container: container }

  def packed_item(**parents)
    create :packed_item, { box: nil, pallet: nil, container: nil, shipment: nil, quantity: 2 }.merge(parents)
  end

  # Puts a row out of sync without running callbacks, as if a parent changed underneath it.
  def desync(item, **attrs)
    item.update_columns({ status: PackedItem::ARCHIVED, shipment_id: nil }.merge(attrs))
    item
  end

  def sync(*items)
    PackedItem.where(id: items.map(&:id)).sync_with_parents!
    items.each(&:reload)
  end

  it "takes a container item's status and shipment from the container" do
    item = desync(packed_item(container: container))
    sync(item)

    expect(item).to have_attributes(status: container.status, shipment_id: shipment.id)
  end

  it "takes a pallet item's shipment through the pallet's container" do
    item = desync(packed_item(pallet: pallet))
    sync(item)

    expect(item).to have_attributes(status: pallet.reload.status, shipment_id: shipment.id)
  end

  it "takes a box item's shipment through a pallet's container" do
    item = desync(packed_item(box: create(:box, pallet: pallet, container: nil)))
    sync(item)

    expect(item.shipment_id).to eq(shipment.id)
  end

  it "takes a box item's shipment directly from the box's container" do
    item = desync(packed_item(box: create(:box, container: container, pallet: nil)))
    sync(item)

    expect(item.shipment_id).to eq(shipment.id)
  end

  it "takes the box's status, not the pallet's, for a boxed item" do
    box = create :box, pallet: pallet, container: nil
    box.update_columns(status: Box::COMPLETE)
    item = desync(packed_item(box: box))
    sync(item)

    expect(item.status).to eq(Box::COMPLETE)
  end

  it "clears the shipment when the parent chain has none" do
    item = packed_item(box: create(:box, pallet: create(:pallet, container: nil), container: nil))
    item.update_columns(shipment_id: shipment.id)
    sync(item)

    expect(item.shipment_id).to be_nil
  end

  it "leaves an unassigned item's status alone and clears its shipment" do
    item = packed_item(status: PackedItem::STAGED)
    item.update_columns(shipment_id: shipment.id)
    sync(item)

    expect(item).to have_attributes(status: PackedItem::STAGED, shipment_id: nil)
  end

  it "matches what saving each item through its callbacks would produce" do
    items = [
      packed_item(container: container),
      packed_item(pallet: pallet),
      packed_item(box: create(:box, pallet: pallet, container: nil)),
      packed_item(box: create(:box, container: container, pallet: nil)),
      packed_item(status: PackedItem::WAREHOUSED)
    ]
    expected = items.map { |i| [i.reload.status, i.shipment_id] }

    items.each { |i| desync(i) unless i.status == PackedItem::WAREHOUSED }
    sync(*items)

    expect(items.map { |i| [i.status, i.shipment_id] }).to eq(expected)
  end

  it "only updates items in the current scope" do
    in_scope = desync(packed_item(container: container))
    out_of_scope = desync(packed_item(container: container))
    sync(in_scope)

    expect(out_of_scope.reload).to have_attributes(status: PackedItem::ARCHIVED, shipment_id: nil)
  end

  it "only touches rows that change" do
    in_sync = packed_item(container: container)
    stale = desync(packed_item(container: container))
    in_sync.update_columns(updated_at: 1.day.ago)
    stale.update_columns(updated_at: 1.day.ago)

    sync(in_sync, stale)

    expect(in_sync.updated_at).to be < 1.hour.ago
    expect(stale.updated_at).to be > 1.minute.ago
  end

  it "leaves remaining quantity alone" do
    item = desync(packed_item(container: container), remaining_quantity: 1)
    sync(item)

    expect(item.remaining_quantity).to eq(1)
  end

  it "runs in a single query regardless of item count" do
    items = Array.new(5) { desync(packed_item(container: container)) }

    expect(count_queries { PackedItem.where(id: items.map(&:id)).sync_with_parents! }).to eq(1)
  end
end
