module Forms
  class SubmitAnswersController < BaseController
    def submit_answers
      if current_context.form_submitted?
        redirect_to error_repeat_submission_path(current_form.id)
      else
        unless mode.preview?
          EventLogger.log_form_event(current_context, request, "submission")
        end

        FormSubmissionService.call(form: current_context,
                                   reference: params[:notify_reference],
                                   preview_mode: mode.preview?).submit_form_to_processing_team
        redirect_to :form_submitted
      end
    rescue StandardError => e
      Sentry.capture_exception(e)
      render "errors/submission_error", status: :internal_server_error
    end
  end
end
