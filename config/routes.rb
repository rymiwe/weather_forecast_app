Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Set the root path to forecasts index
  root "forecasts#index"
  
  # Add our custom routes first so they don't get interpreted as IDs
  get 'forecasts/search', to: 'forecasts#search', as: :search_forecasts
  post 'forecasts/search', to: 'forecasts#search'
  
  # Add Turbo-compatible refresh route
  get 'forecasts/refresh', to: 'forecasts#refresh', as: :refresh_forecast
  
  # Only define the routes we need (index and show)
  resources :forecasts, only: [:index] do
    member do
      post 'set_units'
      post 'refresh_cache' # Legacy route for refreshing the cache
    end
  end
end
