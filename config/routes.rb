Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "home#index"

  resources :form, only: %i[show], path: "/" do
    get :check_your_answers
    get :submitted
    post :submit_answers

    resources :page, only: %i[show create], path: "/", param: :page_id do
      post :submit, on: :member
    end
  end
end
