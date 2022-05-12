Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "home#index"
  resources :forms, only: [:index] do
    resource :page, module: 'forms', only: [:show, :create], path: "/" do
      get :submitted
    end
  end
end
