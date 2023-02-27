module Forms
  class SubmitAnswersController < BaseController
    def submit_answers
      redirect_to :form_submitted if current_context.submit_users_answers(params[:notify_reference], preview?, request)

    rescue StandardError => e
      Sentry.capture_exception(e)
      render "errors/submission_error", status: :internal_server_error
    end
  end
end
