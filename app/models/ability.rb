# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    alias_action :create, :read, :update, :destroy, to: :crud
    alias_action :create, :read, to: :cr
    alias_action :create, :read, :update, to: :cru
    alias_action :create, :update, :delete, to: :cud

    case user.role
    when "Volunteer"
      can :cru, User, id: user.id
      cannot :index, User
      cannot :alter_role, User
      cannot :manage, [Item, Warehouse, Hospital, Category, Shipment, Container]
      cannot :manage, UnpackingEvent
      can :manage, PackedItem
      can :cr, Item
      can :manage, Box, status: Box::IN_PROGRESS
      can :read, Box, status: Box::COMPLETE
      can :manage, Pallet, status: Pallet::IN_PROGRESS
      can :read, Pallet, status: Pallet::COMPLETE
      can :read, Container, status: [Container::IN_PROGRESS, Container::COMPLETE]
      cannot :read, Pallet, status: Pallet::RECEIVED
      cannot :read, Box, status: Box::RECEIVED
    when "Shipping Manager"
      can :read, [Warehouse, Hospital, Shipment]
      cannot :cud, [Warehouse, Shipment, Container]
      can :manage, [Item, User, Category, Container, Pallet, Box]
      cannot :manage, UnpackingEvent
      can :manage, PackedItem
      can :reconcile, Item
    when "Receiving Manager"
      can :cru, User, id: user.id
      can :read, Item
      can :read, Category
      can :manage, Hospital, warehouse: user.warehouse
      can :read, Shipment, receiving_warehouse: user.warehouse, status: Shipment::RECEIVED
      can :read, Container, shipment: { receiving_warehouse_id: user.warehouse_id }, status: Container::RECEIVED
      can :read, Pallet, shipment: { receiving_warehouse_id: user.warehouse_id }, status: Pallet::RECEIVED
      can :find, Pallet, shipment: { receiving_warehouse_id: user.warehouse_id }, status: Pallet::RECEIVED
      can :read, Box, container: { shipment: { receiving_warehouse_id: user.warehouse_id } }, status: Box::RECEIVED
      can :unpack_all, Box, container: { shipment: { receiving_warehouse_id: user.warehouse_id } }, status: Box::RECEIVED
      can :unpack_all, Box, pallet: { container: { shipment: { receiving_warehouse_id: user.warehouse_id } } }, status: Box::RECEIVED
      can :unpack_all, Pallet, shipment: { receiving_warehouse_id: user.warehouse_id }, status: Pallet::RECEIVED
      can :find, Box, container: { shipment: { receiving_warehouse_id: user.warehouse_id } }, status: Box::RECEIVED
      can :read, Box, pallet: { container: { shipment: { receiving_warehouse_id: user.warehouse_id } } }, status: Box::RECEIVED
      can :manage, UnpackingEvent
      can :read, PackedItem, shipment: { receiving_warehouse_id: user.warehouse_id }
      cannot :cud, PackedItem
      cannot :manage, Item
    when "Admin"
      can :manage, :all
    end
  end
end
