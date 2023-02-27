module Forms
  class SubmitAnswersController < BaseController
    def submit_answers
      unless preview?
        EventLogger.log_form_event(current_context, request, "submission")
      end
      if form.email.nil?
        Sentry.capture_message("preview submitted, caught")
        render "errors/submission_error", status: :internal_server_error
      else
        FormSubmissionService.call(form: current_context,
                                 reference: params[:notify_reference],
                                 preview_mode: preview?).submit_form_to_processing_team

      end

      current_context.clear
      redirect_to :form_submitted
    rescue StandardError => e
      Sentry.capture_exception(e)
      render "errors/submission_error", status: :internal_server_error
    end
  end
end
