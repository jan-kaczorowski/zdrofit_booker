Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  mount SolidQueueDashboard::Engine, at: "/solid-queue"

  # PWA manifest and service worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"

  post "/login", to: "home#login"
  get "/dashboard", to: "home#dashboard", as: :dashboard
  get "/weekly_classes", to: "home#weekly_classes"
  get "/ongoing_bookings", to: "home#ongoing_bookings"
  post "/book", to: "home#book"
  delete "/bookings/:id", to: "home#cancel_booking", as: :cancel_booking
  post "/update_location", to: "home#update_location"
  delete "/logout", to: "home#logout", as: :logout
end
