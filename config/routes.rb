Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "home#index"

  resources :form, only: %i[show], path: "/" do
    resources :page, only: %i[show], path: "/" do
      get :submitted
    end
  end
end
