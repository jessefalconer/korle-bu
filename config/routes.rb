# frozen_string_literal: true

Rails.application.routes.draw do
  root "sessions#new"

  get "/privacy", to: static("privacy.html")
  get "/terms", to: static("terms.html")
  get "/admin_help", to: static("admin_help.html")
  get "/dev_updates", to: static("dev_updates.html")
  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  get "logout", to: "sessions#destroy"
  get "index", to: "sessions#index"
  get "my_activity", to: "sessions#my_activity"

  get "signup", to: "users#signup"
  post "create_public_user", to: "users#create_public_user"

  get "item_search", to: "items#search"
  get "item_search_form", to: "items#search_form"
  get "reconcile_unverified", to: "reconcile_items#unverified"
  get "reconcile_uncategorized", to: "reconcile_items#uncategorized"
  get "reconcile_flagged", to: "reconcile_items#flagged"
  get "reconcile/:id", to: "reconcile_items#start", as: :reconcile_start
  get "reconcile/:id/confirm/:target_id", to: "reconcile_items#confirm", as: :reconcile_confirm
  get "reconcile/:id/execute_reconcile/:target_id", to: "reconcile_items#execute", as: :execute_reconcile
  get "reconcile/:id/item_instances", to: "reconcile_items#item_instances", as: :item_instances

  resources :exports, only: :create
  resources :categories
  resources :items
  resources :users do
    member do
      patch :change_password
    end
  end
  resources :warehouses

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
