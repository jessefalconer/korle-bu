# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    case user.role
    when "Volunteer"
      cannot :manage, [Item, Warehouse, Category, Shipment, Container]
      cannot :reassign, Container
    when "Shipping Manager"
      cannot :manage, [Warehouse, Shipment, Container]
      can :manage, [Item, User, Category]
      can :containerize_items, Container
      can :reassign, Container
    when "Receiving Manager"
      # not yet defined
    when "Admin"
      can :manage, [Item, Warehouse, User, Category, Shipment, Container]
      can :reassign, Container
    end
  end
end
