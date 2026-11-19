# frozen_string_literal: true

Rails.application.routes.draw do
  root "sessions#index", as: :index

  # Health check for the server's monitoring: 200 if the app boots, 500 otherwise.
  get "up" => "rails/health#show", as: :rails_health_check

  StaticPagesController::PAGES.each do |page|
    get "/#{page}", to: "static_pages#show", page: page, as: page
  end
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
  post "received_categories/unpack_selected", to: "packed_items#unpack_selected"

  resources :unpacking_events, only: %i[index update]
  resources :hospital_exports, only: :create
  resources :shipment_exports, only: :create
  resources :unpacking_events_exports, only: :create
  resources :categories, except: :edit
  resources :items, except: :edit
  resources :users, except: :edit do
    member do
      patch :change_password
    end
  end
  resources :warehouses, except: :edit
  resources :hospitals, except: :edit
  resources :staged_items, except: %i[new show edit]
  post "staged_item_add_with_item", to: "staged_items#add_with_item"
  resources :warehoused_items, except: %i[new show edit]
  post "warehoused_item_add_with_item", to: "warehoused_items#add_with_item"
  post "boxes/:id/unpack_all", to: "boxes#unpack_all", as: "boxes_unpack_all"
  post "pallets/:id/unpack_all", to: "pallets#unpack_all", as: "pallets_unpack_all"

  concern :boxable_items do
    resources :boxes, except: :edit do
      get "duplicate", to: "boxes#duplicate"
      post "add_with_item", to: "box_items#add_with_item"
      resources :box_items, except: %i[show edit new] do
        resources :box_unpacking_events, only: %i[create destroy]
      end
    end
  end

  concern :palletable_items do
    resources :pallets, except: :edit do
      post "add_with_item", to: "pallet_items#add_with_item"
      resources :pallet_items, except: %i[show edit new] do
        resources :pallet_unpacking_events, only: %i[create destroy]
      end
      concerns :boxable_items
    end
  end

  concern :containable_items do
    resources :containers, except: :edit do
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
  resources :shipments, except: :edit do
    concerns :containable_items
  end

  # match '*unmatched', to: redirect('/404'), via: :all
end
