# frozen_string_literal: true

Rails.application.routes.draw do
  root "sessions#index", as: :index

  get "/privacy", to: static("privacy.html")
  get "/terms", to: static("terms.html")
  get "/admin_help", to: static("admin_help.html")
  get "/volunteer_help", to: static("volunteer_help.html")
  get "/dev_updates", to: static("dev_updates.html")
  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  get "logout", to: "sessions#destroy"
  get "my_activity", to: "sessions#my_activity"

  get "signup", to: "users#signup"
  post "create_public_user", to: "users#create_public_user"

  get "reconcile_item_search", to: "items#reconcile_search"
  get "item_search_form", to: "items#search_form"
  get "index_item_search", to: "items#index_search"
  get "unverified_item_search", to: "items#unverified_search"
  get "uncategorized_item_search", to: "items#uncategorized_search"
  get "packed_item_search", to: "items#packed_search"
  get "reconcile_unverified", to: "reconcile_items#unverified"
  get "reconcile_uncategorized", to: "reconcile_items#uncategorized"
  get "reconcile_flagged", to: "reconcile_items#flagged"
  get "reconcile/:id", to: "reconcile_items#start", as: :reconcile_start
  post "reconcile/:id", to: "reconcile_items#confirm", as: :reconcile_confirm
  post "reconcile/:id/execute_reconcile", to: "reconcile_items#execute", as: :execute_reconcile
  get "reconcile/:id/item_instances", to: "reconcile_items#item_instances", as: :item_instances
  post "find_box", to: "boxes#find"
  post "find_pallet", to: "pallets#find"
  post "mass_action", to: "mass_actions#mass_action"
  get "all_received_items", to: "packed_items#all_received_items"
  get "received_categories", to: "packed_items#received_categories"
  get "received_categories/:id/received_category_items", to: "packed_items#received_category_items", as: :received_category_items
  get "received_category_items/:id/received_item_locations", to: "packed_items#received_item_locations", as: :received_item_locations
  get "received_categories/uncategorized", to: "packed_items#received_uncategorized_items", as: :received_uncategorized_items

  resources :unpacking_events, only: :index
  resources :exports, only: :create
  resources :categories
  resources :items
  resources :users do
    member do
      patch :change_password
    end
  end
  resources :warehouses
  resources :hospitals
  resources :packed_items, only: :index
  resources :staged_items
  post "staged_item_add_with_item", to: "staged_items#add_with_item"
  resources :warehoused_items
  post "warehoused_item_add_with_item", to: "warehoused_items#add_with_item"

  concern :boxable_items do
    resources :boxes do
      post "add_with_item", to: "box_items#add_with_item"
      resources :box_items, except: %i[show edit new] do
        resources :box_unpacking_events, only: %i[create destroy]
      end
    end
  end

  concern :palletable_items do
    resources :pallets do
      post "add_with_item", to: "pallet_items#add_with_item"
      resources :pallet_items, except: %i[show edit new] do
        resources :pallet_unpacking_events, only: %i[create destroy]
      end
      concerns :boxable_items
    end
  end

  concern :containable_items do
    resources :containers do
      post "add_with_item", to: "container_items#add_with_item"
      resources :container_items, except: %i[show edit new] do
        resources :container_unpacking_events, only: %i[create destroy]
      end
      concerns :palletable_items
    end
  end

  concerns :boxable_items
  concerns :palletable_items
  concerns :containable_items
  resources :shipments do
    concerns :containable_items
  end
end
