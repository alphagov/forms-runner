Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "/up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "errors#not_found"

  get "/help/accessibility-statement" => "application#accessibility_statement", as: :accessibility_statement
  get "/help/cookies" => "application#cookies", as: :cookies

  get "/security.txt" => redirect("https://vulnerability-reporting.service.security.gov.uk/.well-known/security.txt")
  get "/submission" => "submission_status#status", as: :status
  get "/.well-known/security.txt" => redirect("https://vulnerability-reporting.service.security.gov.uk/.well-known/security.txt")

  scope "/:mode", mode: /preview-draft|preview-archived|preview-live|form/ do
    get "/:form_id" => "forms/base#redirect_to_friendly_url_start", as: :form_id
    scope "/:form_id/:form_slug" do
      get "/" => "forms/base#redirect_to_friendly_url_start", as: :form
      get "/#{CheckYourAnswersStep::CHECK_YOUR_ANSWERS_PAGE_SLUG}" => "forms/check_your_answers#show", as: :check_your_answers
      post "/#{CheckYourAnswersStep::CHECK_YOUR_ANSWERS_PAGE_SLUG}" => "forms/check_your_answers#submit_answers", as: :form_submit_answers
      get "/submitted" => "forms/submitted#submitted", as: :form_submitted
      get "/privacy" => "forms/privacy_page#show", as: :form_privacy

      page_constraints = { page_slug: Flow::StepFactory::PAGE_SLUG_REGEX }
      answer_constraints = { answer_index: /\d+/ }
      page_answer_defaults = { answer_index: 1 }

      get "/:page_slug/exit" => "forms/exit_pages#show",
          as: :exit_page,
          constraints: page_constraints

      get "/:page_slug/add-another-answer/change" => "forms/add_another_answer#show",
          as: :change_add_another_answer,
          constraints: page_constraints,
          defaults: { changing_existing_answer: true }
      get "/:page_slug/add-another-answer" => "forms/add_another_answer#show",
          as: :add_another_answer,
          constraints: page_constraints
      post "/:page_slug/add-another-answer" => "forms/add_another_answer#save",
           as: :save_add_another_answer,
           constraints: page_constraints

      # We don't currently support adding another answer for file upload questions, so these routes don't include an
      # `answer_index` param
      get "/:page_slug/review-file" => "forms/review_file#show",
          as: :review_file,
          constraints: page_constraints
      post "/:page_slug/review-file" => "forms/review_file#continue",
           as: :review_file_continue,
           constraints: page_constraints
      get "/:page_slug/remove-file" => "forms/remove_file#show",
          as: :remove_file_confirmation,
          constraints: page_constraints
      delete "/:page_slug/remove-file" => "forms/remove_file#destroy",
             as: :remove_file,
             constraints: page_constraints

      get "/:page_slug/(/:answer_index)/change" => "forms/page#show",
          as: :form_change_answer,
          defaults: page_answer_defaults.merge(changing_existing_answer: true),
          constraints: page_constraints.merge(answer_constraints)
      get "/:page_slug(/:answer_index)" => "forms/page#show",
          as: :form_page,
          constraints: page_constraints.merge(answer_constraints),
          defaults: page_answer_defaults
      post "/:page_slug(/:answer_index)" => "forms/page#save",
           as: :save_form_page,
           constraints: page_constraints,
           defaults: page_answer_defaults

      get "/:page_slug/:answer_index/remove" => "forms/remove_answer#show",
          as: :form_remove_answer,
          constraints: page_constraints.merge(answer_constraints)
      delete "/:page_slug/:answer_index/remove" => "forms/remove_answer#delete",
             as: :delete_form_remove_answer,
             constraints: page_constraints.merge(answer_constraints)

      get "/repeat-submission" => "forms/base#error_repeat_submission", as: :error_repeat_submission, via: :all
    end
  end

  get "/maintenance" => "errors#maintenance", as: :maintenance_page
  get "/404", to: "errors#not_found", as: :error_404, via: :all
  get "/500", to: "errors#internal_server_error", as: :error_500, via: :all
  get "/deprecated", to: "errors#deprecated"
  match "*path", to: "errors#not_found", via: :all
end
