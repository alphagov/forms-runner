module Forms
  class SubmitAnswersController < BaseController
    def submit_answers
      unless preview?
        EventLogger.log_form_event(current_context, request, "submission")
      end
      submit_form(answers)
      current_context.clear
      redirect_to :form_submitted
    rescue StandardError => e
      Sentry.capture_exception(e)
      render "errors/submission_error", status: :internal_server_error
    end

  private

    def submit_form(text)
      # in the controller for now but can be moved to service object, maybe use actionmailer fo easier testing?
      NotifyService.new.send_email(current_context.submission_email, current_context.form_name, text, preview_mode: preview?)
    end

    def answers
      current_context.steps.map { |page| "# #{page.question_text}\n#{page.show_answer}" }.join("\n\n---\n\n")
    end
  end
end
