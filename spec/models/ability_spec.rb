# frozen_string_literal: true

require "rails_helper"
require "cancan/matchers"

describe Ability do
  subject(:ability) { Ability.new(user) }

  let(:owner) { create :user }

  def box_with_status(status)
    create(:box, pallet: nil, container: nil, user: owner).tap { |b| b.update!(status: status) }
  end

  def pallet_with_status(status)
    create(:pallet, container: nil, user: owner).tap { |p| p.update!(status: status) }
  end

  context "as a volunteer" do
    let(:user) { create :user, role: "Volunteer" }

    it "can read and update only their own user" do
      expect(ability).to be_able_to(:read, user)
      expect(ability).to be_able_to(:update, user)
      expect(ability).not_to be_able_to(:read, owner)
      expect(ability).not_to be_able_to(:update, owner)
      expect(ability).not_to be_able_to(:index, User)
      expect(ability).not_to be_able_to(:alter_role, user)
    end

    it "can create and read items but not change them" do
      item = create :item
      expect(ability).to be_able_to(:create, Item)
      expect(ability).to be_able_to(:read, item)
      expect(ability).not_to be_able_to(:update, item)
      expect(ability).not_to be_able_to(:destroy, item)
    end

    it "can manage in-progress boxes and pallets" do
      expect(ability).to be_able_to(:update, box_with_status(Box::IN_PROGRESS))
      expect(ability).to be_able_to(:destroy, box_with_status(Box::IN_PROGRESS))
      expect(ability).to be_able_to(:update, pallet_with_status(Pallet::IN_PROGRESS))
    end

    it "can only read complete boxes and pallets" do
      box = box_with_status(Box::COMPLETE)
      pallet = pallet_with_status(Pallet::COMPLETE)

      expect(ability).to be_able_to(:read, box)
      expect(ability).not_to be_able_to(:update, box)
      expect(ability).to be_able_to(:read, pallet)
      expect(ability).not_to be_able_to(:update, pallet)
    end

    it "cannot see received boxes and pallets" do
      expect(ability).not_to be_able_to(:read, box_with_status(Box::RECEIVED))
      expect(ability).not_to be_able_to(:read, pallet_with_status(Pallet::RECEIVED))
    end

    it "can read in-progress and complete containers but not change them" do
      container = create :container, shipment: nil
      expect(ability).to be_able_to(:read, container)
      expect(ability).not_to be_able_to(:update, container)

      container.update!(status: Container::COMPLETE)
      expect(ability).to be_able_to(:read, container)

      container.update!(status: Container::RECEIVED)
      expect(ability).not_to be_able_to(:read, container)
    end

    it "cannot access shipments, warehouses, hospitals, or categories" do
      expect(ability).not_to be_able_to(:read, create(:shipment))
      expect(ability).not_to be_able_to(:read, create(:warehouse))
      expect(ability).not_to be_able_to(:read, create(:hospital))
      expect(ability).not_to be_able_to(:read, create(:category))
    end

    it "can manage packed items but not unpacking events" do
      expect(ability).to be_able_to(:manage, PackedItem)
      expect(ability).not_to be_able_to(:create, UnpackingEvent)
    end
  end

  context "as a shipping manager" do
    let(:user) { create :user, role: "Shipping Manager" }

    it "can read but not create warehouses, hospitals, and shipments" do
      expect(ability).to be_able_to(:read, create(:warehouse))
      expect(ability).to be_able_to(:read, create(:hospital))
      expect(ability).to be_able_to(:read, create(:shipment))
      expect(ability).not_to be_able_to(:create, Warehouse)
      expect(ability).not_to be_able_to(:create, Shipment)
      expect(ability).not_to be_able_to(:update, create(:shipment))
      expect(ability).not_to be_able_to(:update, create(:hospital))
    end

    it "can manage items, users, categories, containers, pallets, and boxes" do
      [Item, User, Category, Container, Pallet, Box].each do |klass|
        expect(ability).to be_able_to(:manage, klass), "expected to manage #{klass}"
      end
    end

    it "can reconcile items" do
      expect(ability).to be_able_to(:reconcile, Item)
    end

    it "cannot manage unpacking events" do
      expect(ability).not_to be_able_to(:create, UnpackingEvent)
    end
  end

  context "as a receiving manager" do
    let(:warehouse) { create :warehouse }
    let(:other_warehouse) { create :warehouse }
    let(:user) { create :user, role: "Receiving Manager", warehouse: warehouse }

    let(:shipment) { create :shipment, receiving_warehouse: warehouse }
    let(:container) { create :container, shipment: shipment }
    let!(:box) { create :box, container: container, pallet: nil }
    let!(:pallet) { create :pallet, container: container }

    def receive(record)
      record.update!(status: Shipment::RECEIVED)
      record
    end

    it "can manage hospitals in their warehouse only" do
      expect(ability).to be_able_to(:update, create(:hospital, warehouse: warehouse))
      expect(ability).not_to be_able_to(:update, create(:hospital, warehouse: other_warehouse))
    end

    it "can read received shipments destined for their warehouse" do
      expect(ability).not_to be_able_to(:read, shipment)
      expect(ability).to be_able_to(:read, receive(shipment))
    end

    it "cannot read received shipments for another warehouse" do
      foreign = receive(create(:shipment, receiving_warehouse: other_warehouse))
      expect(ability).not_to be_able_to(:read, foreign)
    end

    it "can read and unpack received containers, pallets, and boxes" do
      receive(shipment)

      expect(ability).to be_able_to(:read, container.reload)
      expect(ability).to be_able_to(:read, pallet.reload)
      expect(ability).to be_able_to(:unpack_all, pallet)
      expect(ability).to be_able_to(:read, box.reload)
      expect(ability).to be_able_to(:unpack_all, box)
      expect(ability).to be_able_to(:find, box)
    end

    it "cannot read contents that have not been received" do
      expect(ability).not_to be_able_to(:read, container)
      expect(ability).not_to be_able_to(:read, box)
      expect(ability).not_to be_able_to(:read, pallet)
    end

    it "can read but not change received packed items" do
      receive(shipment)
      packed = create :packed_item, box: box.reload, pallet: nil, container: nil

      expect(ability).to be_able_to(:read, packed)
      expect(ability).not_to be_able_to(:update, packed)
      expect(ability).not_to be_able_to(:create, PackedItem)
    end

    it "can manage unpacking events" do
      expect(ability).to be_able_to(:manage, UnpackingEvent)
    end

    it "can only edit their own user" do
      expect(ability).to be_able_to(:update, user)
      expect(ability).not_to be_able_to(:update, owner)
    end
  end

  context "as an admin" do
    let(:user) { create :user, role: "Admin" }

    it "can manage everything" do
      expect(ability).to be_able_to(:manage, :all)
      expect(ability).to be_able_to(:destroy, create(:shipment))
      expect(ability).to be_able_to(:update, box_with_status(Box::ARCHIVED))
    end
  end
end
