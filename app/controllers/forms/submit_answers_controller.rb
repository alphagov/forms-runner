module Forms
  class SubmitAnswersController < BaseController
    def submit_answers
      unless preview?
        EventLogger.log_form_event(current_context, request, "submission")
      end

      NotifyService.new.send_email(current_context, preview_mode: preview?)
      current_context.clear
      redirect_to :form_submitted
    rescue StandardError => e
      Sentry.capture_exception(e)
      render "errors/submission_error", status: :internal_server_error
    end
  end
end
