# frozen_string_literal: true

Rails.application.routes.draw do
  root "sessions#welcome"
  resources :users, only: %i[new create]

  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  get "logout", to: "sessions#destroy"
  get "welcome", to: "sessions#welcome"
  get "authorized", to: "sessions#page_requires_login"
end
