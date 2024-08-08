Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "/up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "errors#not_found"

  get "/help/accessibility-statement" => "application#accessibility_statement", as: :accessibility_statement
  get "/help/cookies" => "application#cookies", as: :cookies

  get "/security.txt" => redirect("https://vdp.cabinetoffice.gov.uk/.well-known/security.txt")
  get "/.well-known/security.txt" => redirect("https://vdp.cabinetoffice.gov.uk/.well-known/security.txt")

  scope "/:mode", mode: /preview-draft|preview-archived|preview-live|form/ do
    get "/:form_id" => "forms/base#redirect_to_friendly_url_start", as: :form_id
    scope "/:form_id/:form_slug" do
      get "/" => "forms/base#redirect_to_friendly_url_start", as: :form
      get "/#{CheckYourAnswersStep::CHECK_YOUR_ANSWERS_PAGE_SLUG}" => "forms/check_your_answers#show", as: :check_your_answers
      post "/#{CheckYourAnswersStep::CHECK_YOUR_ANSWERS_PAGE_SLUG}" => "forms/check_your_answers#submit_answers", as: :form_submit_answers
      get "/submitted" => "forms/submitted#submitted", as: :form_submitted
      get "/privacy" => "forms/privacy_page#show", as: :form_privacy
      get "/:page_slug/change(/:answer_id)" => "forms/page#show", as: :form_change_answer, defaults: { changing_existing_answer: true, answer_id: 1 }
      post "/:page_slug(/:answer_id)" => "forms/page#save", as: :save_form_page, defaults: { answer_id: 1 }
      get "/:page_slug(/:answer_id)" => "forms/page#show",
          constraints: {
            page_slug: Flow::StepFactory::PAGE_SLUG_REGEX,
            answer_id: /\d+/,
          },
          defaults: { answer_id: 1 },
          as: :form_page

      get "/repeat-submission" => "forms/base#error_repeat_submission", as: :error_repeat_submission, via: :all
    end
  end

  get "/maintenance" => "errors#maintenance", as: :maintenance_page
  get "/404", to: "errors#not_found", as: :error_404, via: :all
  get "/500", to: "errors#internal_server_error", as: :error_500, via: :all
  match "*path", to: "errors#not_found", via: :all
end
