module Forms
  class CheckYourAnswersController < BaseController
    def set_request_logging_attributes
      super
      if params[:email_confirmation_input].present? && (email_confirmation_input_params[:send_confirmation] == "send_email")
        CurrentRequestLoggingAttributes.confirmation_email_reference = email_confirmation_input_params[:confirmation_email_reference]
      end
    end

    def show
      return redirect_to form_page_path(current_context.form.id, current_context.form.form_slug, current_context.next_page_slug, nil) unless current_context.can_visit?(CheckYourAnswersStep::CHECK_YOUR_ANSWERS_PAGE_SLUG)

      store_govuk_one_login_return_path
      setup_check_your_answers
      email_confirmation_input = EmailConfirmationInput.new
      @signed_in_email = session[:govuk_one_login_email]

      @support_details = current_context.support_details

      render template: "forms/check_your_answers/show", locals: { email_confirmation_input: }
    end

    def submit_answers
      @support_details = current_context.support_details
      email_confirmation_input = EmailConfirmationInput.new(email_confirmation_input_params)
      requested_email_confirmation = email_confirmation_input.send_confirmation == "send_email"

      unless email_confirmation_input.valid?
        setup_check_your_answers

        return render template: "forms/check_your_answers/show", locals: { email_confirmation_input: }, status: :unprocessable_content
      end

      return redirect_to error_repeat_submission_path(@form.id) if current_context.form_submitted?

      unless current_context.can_visit?(CheckYourAnswersStep::CHECK_YOUR_ANSWERS_PAGE_SLUG)
        EventLogger.log_form_event("incomplete_or_repeat_submission_error")
        return render template: "errors/incomplete_submission", locals: { form: @form, current_context: }
      end

      begin
        submission_reference = FormSubmissionService.call(current_context:,
                                                          email_confirmation_input:,
                                                          mode:).submit

        current_context.save_submission_details(submission_reference, requested_email_confirmation)

        redirect_to :form_submitted
      rescue FormSubmissionService::ConfirmationEmailToAddressError
        setup_check_your_answers
        email_confirmation_input.errors.add(:confirmation_email_address, :invalid_email)
        render template: "forms/check_your_answers/show", locals: { email_confirmation_input: }, status: :unprocessable_content
      end
    rescue StandardError => e
      log_rescued_exception(e)

      render "errors/submission_error", status: :internal_server_error
    end

  private

    def store_govuk_one_login_return_path
      session[:govuk_one_login_last_form_id] = current_context.form.id
      session[:govuk_one_login_last_form_slug] = current_context.form.form_slug
      session[:govuk_one_login_last_mode] = mode.to_s
      session[:govuk_one_login_last_locale] = locale_param
    end

    def email_confirmation_input_params
      params.require(:email_confirmation_input).permit(:send_confirmation, :confirmation_email_address, :confirmation_email_reference)
    end

    def setup_check_your_answers
      @back_link = back_link
      @steps = current_context.completed_steps
      @form_submit_path = form_submit_answers_path

      unless mode.preview?
        EventLogger.log_form_event("check_answers")
      end
    end

    def back_link
      previous_step = current_context.previous_step(CheckYourAnswersStep::CHECK_YOUR_ANSWERS_PAGE_SLUG)

      if previous_step.present?
        previous_step.repeatable? ? add_another_answer_path(form_id: current_context.form.id, form_slug: current_context.form.form_slug, page_slug: previous_step.id) : form_page_path(current_context.form.id, current_context.form.form_slug, previous_step.id)
      end
    end
  end
end
