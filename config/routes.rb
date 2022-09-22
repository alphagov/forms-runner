Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  get :ping, controller: :heartbeat

  # Defines the root path route ("/")
  root "errors#not_found"

  get "/help/accessibility-statement" => "application#accessibility_statement", as: :accessibility_statement
  get "/help/cookies" => "application#cookies", as: :cookies

  scope "/:mode", mode: /preview-form|form/ do
    get "/:form_id" => "forms/base#redirect_to_friendly_url_start", as: :form_id
    scope "/:form_id/:form_slug" do
      get "/" => "forms/base#redirect_to_friendly_url_start", as: :form
      get "/check_your_answers" => "forms/check_your_answers#show", as: :check_your_answers
      post "/submit_answers" => "forms/submit_answers#submit_answers", as: :form_submit_answers
      get "/submitted" => "forms/submitted#submitted", as: :form_submitted
      get "/privacy" => "forms/privacy_page#show", as: :form_privacy
      get "/:page_slug/change" => "forms/page#show", as: :form_change_answer, defaults: { changing_existing_answer: true }
      get "/:page_slug" => "forms/page#show", as: :form_page
      post "/:page_slug" => "forms/page#save", as: :save_form_page
    end

  end

  get "/404", to: "errors#not_found", as: :error_404, via: :all
  get "/500", to: "errors#internal_server_error", as: :error_500, via: :all
  match "*path", to: "errors#not_found", via: :all
end
