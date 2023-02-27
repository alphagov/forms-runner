module Forms
  class SubmitAnswersController < BaseController
    def submit_answers
      unless preview?
        EventLogger.log_form_event(current_context, request, "submission")
      end
      unless current_context.submission_email.nil?
        FormSubmissionService.call(form: current_context,
                                 reference: params[:notify_reference],
                                 preview_mode: preview?).submit_form_to_processing_team
        EventLogger.log_form_event(current_context, request, "no email submission")
      end

      current_context.clear
      redirect_to :form_submitted
    rescue StandardError => e
      Sentry.capture_exception(e)
      render "errors/submission_error", status: :internal_server_error
    end
  end
end
