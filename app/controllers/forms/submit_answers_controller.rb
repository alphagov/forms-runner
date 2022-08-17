module Forms
  class SubmitAnswersController < FormController
    def submit_answers
      EventLogger.log_form_event(current_context, request, "submission")
      submit_form(answers)
      current_context.clear
      redirect_to :form_submitted
    rescue StandardError => exception
      Sentry.capture_exception(exception)
      render "errors/submission_error", status: :internal_server_error
    end

  private

    def submit_form(text)
      # in the controller for now but can be moved to service object, maybe use actionmailer fo easier testing?
      NotifyService.new.send_email(current_context.submission_email, current_context.form_name, text, Time.zone.now)
    end

    def answers
      current_context.steps.map { |page| "#{page.question_text}: #{page.show_answer}" }.join("\n")
    end
  end
end
