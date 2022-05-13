Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "home#index"
  # resources :forms, only: [:index] do
  #   resource :page, module: 'forms', only: [:show, :create], path: "/" do
  #     get :submitted
  #   end
  # end
 # scope '/forms/:form_id', module: 'forms' do
  resources :form, only: [], path: '/' do
   resource :page, only: [:new, :create], module: 'forms', path_names: { new: '/' }, path: '/' do
     get :submitted
   end
 end
end
