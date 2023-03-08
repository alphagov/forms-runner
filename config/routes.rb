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
      get "/#{CheckYourAnswersStep::CHECK_YOUR_ANSWERS_PAGE_SLUG}" => "forms/check_your_answers#show", as: :check_your_answers
      post "/submit-answers" => "forms/submit_answers#submit_answers", as: :form_submit_answers
      get "/submitted" => "forms/submitted#submitted", as: :form_submitted
      get "/privacy" => "forms/privacy_page#show", as: :form_privacy
      get "/:page_slug/change" => "forms/page#show", as: :form_change_answer, defaults: { changing_existing_answer: true }
      get "/:page_slug" => "forms/page#show", constraints: { page_slug: StepFactory::PAGE_SLUG_REGEX }, as: :form_page
      post "/:page_slug" => "forms/page#save", as: :save_form_page

      get "/session-expired", to: "forms/base#session_expired", as: :error_session_expired, via: :all
    end
  end

  get "/404", to: "errors#not_found", as: :error_404, via: :all
  get "/500", to: "errors#internal_server_error", as: :error_500, via: :all
  match "*path", to: "errors#not_found", via: :all
end
