# frozen_string_literal: true

Rails.application.routes.draw do
  root "sessions#new"
  resources :users, only: %i[new create]

  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  get "logout", to: "sessions#destroy"
  get "index", to: "sessions#index"

  get "container_list", to: "containers#list"
  get "pallet_list", to: "pallets#list"
  get "item_list", to: "items#list"
  resources :boxed_items

  resources :warehouses
  resources :containerized_items
  resources :palletized_items
  resources :boxed_items
  resources :shipments do
    resources :containers do
      resources :pallets do
        resources :boxes do
        end
      end
    end
  end
end
