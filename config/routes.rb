# frozen_string_literal: true

Rails.application.routes.draw do
  root "sessions#new"

  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  get "logout", to: "sessions#destroy"
  get "index", to: "sessions#index"

  get "container_list", to: "containers#list"
  get "pallet_list", to: "pallets#list"
  get "item_list", to: "items#list"
  get "box_list", to: "boxes#list"

  get "item_search", to: "items#search"

  resources :categories
  resources :items
  resources :users
  resources :warehouses

  concern :boxable_items do
    resources :boxes do
      resources :boxed_items
    end
  end

  concern :palletable_items do
    resources :pallets do
      resources :palletized_items
      concerns :boxable_items
    end
  end

  concern :containable_items do
    resources :containers do
      resources :containerized_items
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
