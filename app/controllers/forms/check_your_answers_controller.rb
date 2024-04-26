module Forms
  class CheckYourAnswersController < BaseController
    def show
      return redirect_to form_page_path(current_context.form.id, current_context.form.form_slug, current_context.next_page_slug) unless current_context.can_visit?(CheckYourAnswersStep::CHECK_YOUR_ANSWERS_PAGE_SLUG)

      setup_check_your_answers
      email_confirmation_form = EmailConfirmationForm.new

      render template: "forms/check_your_answers/show", locals: { email_confirmation_form: }
    end

    def submit_answers
      email_confirmation_form = EmailConfirmationForm.new(email_confirmation_form_params)
      requested_email_confirmation = email_confirmation_form.send_confirmation == "send_email"

      if email_confirmation_form.valid?
        if current_context.form_submitted?
          redirect_to error_repeat_submission_path(current_form.id)
        else
          unless current_context.can_visit?(CheckYourAnswersStep::CHECK_YOUR_ANSWERS_PAGE_SLUG)
            message = "current_context.can_visit? is false, about to do incomplete or repeat submission?"
            EventLogger.log_form_event(logging_context, "incomplete_or_repeat_submission_error")
            Sentry.capture_message(message)
          end

          submission_reference = FormSubmissionService.call(logging_context:,
                                                            current_context:,
                                                            request:,
                                                            email_confirmation_form:,
                                                            preview_mode: mode.preview?).submit

          current_context.save_submission_details(submission_reference, requested_email_confirmation)

          redirect_to :form_submitted
        end
      else
        setup_check_your_answers

        render template: "forms/check_your_answers/show", locals: { email_confirmation_form: }, status: :unprocessable_entity
      end
    rescue StandardError => e
      log_rescued_exception(e)

      render "errors/submission_error", status: :internal_server_error
    end

  private

    def page_to_row(page)
      question_name = helpers.question_text_with_optional_suffix_inc_mode(page, @mode)
      {
        key: { text: question_name },
        value: { text: page.show_answer },
        actions: [{ href: form_change_answer_path(page.form_id, page.form_slug, page.page_id), visually_hidden_text: question_name }],
      }
    end

    def check_your_answers_rows
      current_context.completed_steps.map { |page| page_to_row(page) }
    end

    def answers_need_full_width
      @full_width = current_context.completed_steps.any? { |step| step.question.has_long_answer? }
    end

    def email_confirmation_form_params
      params.require(:email_confirmation_form).permit(:send_confirmation, :confirmation_email_address, :confirmation_email_reference, :submission_email_reference)
    end

    def setup_check_your_answers
      previous_step = current_context.previous_step("check_your_answers")
      @back_link = form_page_path(current_context.form.id, current_context.form.form_slug, previous_step)
      @rows = check_your_answers_rows
      @form_submit_path = form_submit_answers_path

      unless mode.preview?
        EventLogger.log_form_event(logging_context, "check_answers")
      end

      answers_need_full_width
    end

    def set_logging_context
      super
      if params[:email_confirmation_form].present?
        logging_context[:notification_references] = {}.tap do |h|
          h[:confirmation_email_reference] = email_confirmation_form_params[:confirmation_email_reference] if email_confirmation_form_params[:send_confirmation] == "send_email"
          h[:submission_email_reference] = email_confirmation_form_params[:submission_email_reference]
        end
      end
    end
  end
end
