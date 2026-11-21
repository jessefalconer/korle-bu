# frozen_string_literal: true

require "rails_helper"

# Each role may only reach what its Ability allows, including on endpoints
# that used to check nothing beyond being signed in.
describe "Role authorization", type: :request do
  let!(:admin) { create :user, status: "Active", role: "Admin" }
  let(:warehouse) { create :warehouse, user: admin }
  let(:other_warehouse) { create :warehouse, user: admin }
  let(:volunteer) { create :user, status: "Active", role: "Volunteer", warehouse: warehouse }
  let(:shipping_manager) { create :user, status: "Active", role: "Shipping Manager", warehouse: warehouse }
  let(:receiving_manager) { create :user, status: "Active", role: "Receiving Manager", warehouse: warehouse }

  let(:open_box) { create :box, pallet: nil, container: nil, status: Box::IN_PROGRESS }
  let!(:complete_box) { create :box, pallet: nil, container: nil, status: Box::COMPLETE }
  let(:item) { create :item }

  def packed_in(box, **attrs)
    create :packed_item, box: box, pallet: nil, container: nil, shipment: nil, item: item, quantity: 5, **attrs
  end

  def denied?
    response.redirect? && flash[:error] == "This action is not permitted with your user role."
  end

  describe "the user list" do
    it "is closed to receiving managers, who may still see their own profile" do
      sign_in receiving_manager

      get users_path
      expect(denied?).to be(true)

      get user_path(receiving_manager)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "reconciliation" do
    it "is closed to volunteers" do
      original = item
      duplicate = create :item
      sign_in volunteer

      get reconcile_unverified_path
      expect(denied?).to be(true)

      expect do
        post execute_reconcile_path(original), params: { confirmed_reconcile_ids: [duplicate.id], delete_item: "true" }
      end.not_to change(Item, :count)
    end

    it "is open to shipping managers" do
      sign_in shipping_manager
      get reconcile_unverified_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "exports" do
    let(:hospital) { create :hospital, warehouse: warehouse }

    it "are admin-only" do
      sign_in receiving_manager
      post hospital_exports_path, params: { hospital_export: { id: hospital.id } }

      expect(denied?).to be(true)
    end
  end

  describe "packing into boxes" do
    let(:params) { { packed_item: { item_id: item.id, quantity: 2 } } }

    it "lets a volunteer pack into an in-progress box" do
      sign_in volunteer

      expect { post box_box_items_path(open_box), params: params }.to change(PackedItem, :count).by(1)
    end

    it "stops a volunteer packing into a complete box" do
      sign_in volunteer

      expect { post box_box_items_path(complete_box), params: params }.not_to change(PackedItem, :count)
    end

    it "stops a volunteer editing or deleting an item in a complete box, by any route" do
      packed = packed_in(complete_box)
      sign_in volunteer

      patch staged_item_path(packed), params: { packed_item: { quantity: 99 } }
      patch box_box_item_path(open_box, packed), params: { packed_item: { quantity: 99 } }
      delete warehoused_item_path(packed)

      expect(packed.reload.quantity).to eq(5)
    end

    it "stops a volunteer moving a staged item into a complete box" do
      staged = create :packed_item, box: nil, pallet: nil, container: nil, shipment: nil, item: item, status: PackedItem::STAGED
      sign_in volunteer

      patch staged_item_path(staged), params: { packed_item: { box_id: complete_box.id } }
      expect(staged.reload.box_id).to be_nil
    end

    describe "staging" do
      let(:staged_params) { { packed_item: { item_id: item.id, quantity: 2, status: PackedItem::STAGED } } }

      it "is open to volunteers" do
        sign_in volunteer

        expect { post staged_items_path, params: staged_params }.to change(PackedItem, :count).by(1)
      end

      it "is closed to receiving managers" do
        sign_in receiving_manager

        expect { post staged_items_path, params: staged_params }.not_to change(PackedItem, :count)
      end
    end
  end

  describe "mass actions" do
    it "moves items between open boxes for a volunteer" do
      packed = packed_in(open_box)
      other_open = create :box, pallet: nil, container: nil, status: Box::IN_PROGRESS
      sign_in volunteer

      post mass_action_path, params: { packed_item_ids: [packed.id], box_id: other_open.id, redirect: "/" }
      expect(packed.reload.box_id).to eq(other_open.id)
    end

    it "moves nothing if any item is out of bounds" do
      allowed = packed_in(open_box)
      locked = packed_in(complete_box)
      sign_in volunteer

      post mass_action_path, params: { packed_item_ids: [allowed.id, locked.id], status: PackedItem::STAGED, redirect: "/" }
      expect(allowed.reload.box_id).to eq(open_box.id)
      expect(locked.reload.box_id).to eq(complete_box.id)
    end
  end

  describe "box duplication limits" do
    before do
      open_box
      sign_in shipping_manager
    end

    it "copies up to 10 at a time" do
      expect { post box_duplicate_path(open_box), params: { duplication_count: 10 } }.to change(Box, :count).by(10)
    end

    it "refuses more than 10, or none" do
      expect { post box_duplicate_path(open_box), params: { duplication_count: 11 } }.not_to change(Box, :count)
      expect(flash[:error]).to eq("Duplicate between 1 and 10 copies at a time.")
      expect { post box_duplicate_path(open_box), params: { duplication_count: 0 } }.not_to change(Box, :count)
    end

    it "is no longer reachable by GET" do
      get "/boxes/#{open_box.id}/duplicate", params: { duplication_count: 2 }
      expect(Box.count).to eq(2)
    end
  end

  describe "box duplication" do
    it "is refused for a box the volunteer may not create" do
      sign_in volunteer

      expect do
        post box_duplicate_path(complete_box), params: { duplication_count: 2 }
      end.not_to change(Box, :count)
    end
  end

  describe "unpacking" do
    let(:shipment) { create :shipment, receiving_warehouse: warehouse, status: Shipment::RECEIVED }
    # A packed item's shipment comes from its location, so it sits in a received container.
    let(:received_container) { create :container, shipment: shipment, status: Container::RECEIVED }
    let(:received_item) do
      create :packed_item, box: nil, pallet: nil, container: received_container, shipment: shipment, item: item,
                           quantity: 4, remaining_quantity: 4, status: PackedItem::RECEIVED
    end
    let(:own_hospital) { create :hospital, warehouse: warehouse }
    let(:other_hospital) { create :hospital, warehouse: other_warehouse }

    def unpack_to(hospital)
      post received_categories_unpack_selected_path, params: { item_ids: [received_item.id], hospital_id: hospital.id }
    end

    it "lets a receiving manager unpack to their own warehouse's hospitals" do
      sign_in receiving_manager

      expect { unpack_to(own_hospital) }.to change(UnpackingEvent, :count).by(1)
    end

    it "stops a receiving manager unpacking to another warehouse's hospital" do
      sign_in receiving_manager

      expect { unpack_to(other_hospital) }.not_to change(UnpackingEvent, :count)
    end

    it "explains when no items are ticked" do
      sign_in receiving_manager
      post received_categories_unpack_selected_path, params: { hospital_id: own_hospital.id }

      expect(flash[:error]).to eq("Select at least one item to unpack.")
    end

    it "reports items it could not unpack instead of claiming success" do
      sign_in receiving_manager
      received_item # stock of 4
      create :unpacking_event, packed_item: received_item, hospital: own_hospital, quantity: 4
      received_item.update_columns(remaining_quantity: 4) # stale count, as with a double submit

      expect { unpack_to(own_hospital) }.not_to change(UnpackingEvent, :count)
      expect(flash[:success]).to eq("0 item(s) unpacked.")
      expect(flash[:error]).to include("can't be more than the 0 remaining")
    end

    it "stops volunteers unpacking" do
      sign_in volunteer

      expect { unpack_to(own_hospital) }.not_to change(UnpackingEvent, :count)
    end

    it "stops a receiving manager editing another warehouse's events" do
      event = create :unpacking_event, packed_item: received_item, hospital: other_hospital, quantity: 1,
                                       timestamp: 2.days.ago
      sign_in receiving_manager

      patch unpacking_event_path(event), params: { unpacking_event: { timestamp: Time.zone.now } }
      expect(event.reload.timestamp).to be < 1.day.ago
    end
  end
end
