Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  get :ping, controller: :heartbeat

  # Defines the root path route ("/")
  root "errors#not_found"

  get "/form/:id" => "form#show", as: :form
  get "/preview-form/:id" => "form#show", defaults: { preview: true }, as: :preview_form
  get "/help/accessibility-statement" => "help#accessibility_statement", as: :accessibility_statement
  get "/help/cookies" => "help#cookies", as: :cookies

  get "/form/:form_id/check_your_answers" => "forms/check_your_answers#show", as: :check_your_answers
  post "/form/:form_id/submit_answers" => "forms/submit_answers#submit_answers", as: :form_submit_answers
  get "/form/:form_id/submitted" => "forms/submitted#submitted", as: :form_submitted
  get "/preview-form/:form_id/check_your_answers" => "forms/check_your_answers#show", defaults: { preview: true }, as: :preview_check_your_answers
  post "/preview-form/:form_id/submit_answers" => "forms/submit_answers#submit_answers", defaults: { preview: true }, as: :preview_form_submit_answers
  get "/preview-form/:form_id/submitted" => "forms/submitted#submitted", defaults: { preview: true }, as: :preview_form_submitted

  get "/form/:form_id/:page_slug/change" => "forms/page#show", as: :form_change_answer, defaults: { changing_existing_answer: true }
  get "/preview-form/:form_id/:page_slug/change" => "forms/page#show", as: :preview_form_change_answer, defaults: { changing_existing_answer: true, preview: true }
  get "/form/:form_id/:page_slug" => "forms/page#show", as: :form_page
  get "/preview-form/:form_id/:page_slug" => "forms/page#show", defaults: { preview: true }, as: :preview_form_page
  post "/form/:form_id/:page_slug" => "forms/page#save", as: :save_form_page
  post "/preview-form/:form_id/:page_slug" => "forms/page#save", defaults: { preview: true }, as: :preview_save_form_page

  get "/404", to: "errors#not_found", as: :error_404, via: :all
  get "/500", to: "errors#internal_server_error", as: :error_500, via: :all
  match "*path", to: "errors#not_found", via: :all
end
