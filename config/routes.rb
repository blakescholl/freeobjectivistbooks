FreeBooks::Application.routes.draw do
  ActiveAdmin.routes(self)

  # User-facing

  root to: "home#index"
  get "home" => "home#home"
  get "about" => "home#about"

  get "profile" => "profile#show"

  get "donate" => "requests#index"
  resources :requests do
    get "cancel", on: :member
    resource :donation, only: [:create]
  end

  resources :donations, only: [:index, :destroy] do
    get "pay", on: :collection
    get "cancel", on: :member
    resource :status, only: [:edit, :update]
    resources :messages, only: [:new, :create]
    resources :thanks, only: [:new, :create], controller: :messages, defaults: {is_thanks: true}
    resource :flag, only: [:new, :create, :destroy] do
      get "fix", on: :member
    end
    resource :fulfillment, only: [:create]
  end

  resources :fulfillments, only: [:show]
  get "volunteer" => "fulfillments#volunteer"

  resources :testimonials, only: [:index, :show] do
    collection do
      get "students"
      get "donors"
    end
  end

  resources :locations, only: :index

  get "login" => "sessions#new"
  post "login" => "sessions#create"
  match "logout" => "sessions#destroy"

  resources :users, only: [:create]
  get "signup/read" => "users#read"
  get "signup/donate" => "users#donate"
  get "signup/volunteer" => "users#volunteer"
  get "volunteer/thanks" => "users#volunteer_thanks"

  resource :password, only: [:edit, :update], path_names: {edit: "reset"} do
    member do
      get "forgot"
      post "request_reset"
    end
  end

  # Admin
  get "admin" => "admin#index"
  namespace :admin do
    resources :users do
      post "spoof", on: :member
    end
    resources :requests
    resources :pledges
    resources :donations
    resources :events
    resources :reviews
    resources :referrals
    resources :testimonials
    resources :campaign_targets, only: [:index, :new, :create, :destroy]
  end

  # Test
  match "test/noop"
  match "test/exception"
  match "test/blocked"

  # Catchall to send unknown routes to 404
  match "*path" => "errors#not_found"
end
