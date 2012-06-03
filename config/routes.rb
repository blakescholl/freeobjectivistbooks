FreeBooks::Application.routes.draw do
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
    get "cancel", on: :member
    resource :status, only: [:edit, :update]
    resources :messages, only: [:new, :create]
    resources :thanks, only: [:new, :create], controller: :messages, defaults: {is_thanks: true}
    resource :flag, only: [:new, :create, :destroy] do
      get "fix", on: :member
    end
  end

  resources :testimonials, only: :index

  get "login" => "sessions#new"
  post "login" => "sessions#create"
  match "logout" => "sessions#destroy"

  resources :users, only: [:create]
  get "signup/read" => "users#read"
  get "signup/donate" => "users#donate"

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
    resources :events
    resources :reviews
    resources :referrals
    resources :campaign_targets, only: [:index, :new, :create, :destroy]
  end

  # Test
  match "test/noop"
  match "test/exception"
  get "test/buttons"

  # Catchall to send unknown routes to 404
  match "*path" => "errors#not_found"
end
