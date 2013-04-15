FreeBooks::Application.routes.draw do
  ActiveAdmin.routes(self)

  # User-facing

  root to: "home#index"
  get "home" => "home#home"
  get "about" => "home#about"
  get "terms" => "home#terms"
  get "privacy" => "home#privacy"

  get "profile" => "profile#show"

  get "donate" => "requests#index"
  resources :requests do
    member do
      get "cancel"
      get "renew" => "requests#edit", defaults: {renew: true}
      put "renew"
    end
    resource :donation, only: [:create]
  end

  resources :donations, only: [:index, :destroy] do
    get "send" => "donations#outstanding", on: :collection
    get "cancel", on: :member
    resource :status, only: [:edit, :update]
    resources :messages, only: [:new, :create]
    resources :thanks, only: [:new, :create], controller: :messages, defaults: {is_thanks: true}
    resource :flag, only: [:new, :create, :destroy] do
      get "fix", on: :member
    end
    resource :fulfillment, only: [:create]
  end

  resources :orders, only: [:create, :show] do
    put "pay", on: :member
    resources :contributions, only: [:create]
  end

  resources :contributions, only: [:create] do
    get "test", on: :collection
  end

  resources :fulfillments, only: [:index, :show]
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

  # Workaround for ActiveAdmin problem as per https://github.com/gregbell/active_admin/issues/221
  namespace :admin2 do
    resources :users do
      resources :contributions
    end
    resources :orders do
      resources :contributions
    end
  end

  # Test
  match "test/noop"
  match "test/exception"
  match "test/blocked"

  # Catchall to send unknown routes to 404
  match "*path" => "errors#not_found"
end
