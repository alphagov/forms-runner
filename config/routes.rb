Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "home#index"

  resources :form, only: %i[show], path: "/" do
    get :check_your_answers

    resources :page, only: %i[show], path: "/", param: :page_id do
      post :submit, on: :member
    end
  end

  get "/:form_id/:page_id/change" => "page#show", as: :change_form_page, defaults: { changing_existing_answer: true }
end
