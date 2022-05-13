Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "home#index"

  resources :form, only: [], path: '/' do
    resource :page, only: [:new, :create], module: 'forms', path_names: { new: '/' }, path: '/' do
      get :submitted
    end
  end
end
