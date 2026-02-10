module Forms
  class CheckYourAnswersController < BaseController
    def set_request_logging_attributes
      super
      if email_confirmation_input.send_confirmation == "send_email"
        CurrentRequestLoggingAttributes.confirmation_email_reference = email_confirmation_input.confirmation_email_reference
      end
    end

    def show
      return redirect_to form_page_path(current_context.form.id, current_context.form.form_slug, current_context.next_page_slug, nil) unless current_context.can_visit?(CheckYourAnswersStep::CHECK_YOUR_ANSWERS_PAGE_SLUG)

      setup_check_your_answers
      @signed_in_email = session[:govuk_one_login_email]
      @support_details = current_context.support_details
      @email_confirmation_summary = email_confirmation_summary
    end

    def submit_answers
      @support_details = current_context.support_details
      @signed_in_email = session[:govuk_one_login_email]
      confirmation_input = email_confirmation_input
      requested_email_confirmation = confirmation_input.send_confirmation == "send_email"

      unless confirmation_input.valid?
        setup_email_confirmation_page(confirmation_input)
        return render template: "forms/email_confirmation/show", status: :unprocessable_content
      end

      return redirect_to error_repeat_submission_path(@form.id) if current_context.form_submitted?

      unless current_context.can_visit?(CheckYourAnswersStep::CHECK_YOUR_ANSWERS_PAGE_SLUG)
        EventLogger.log_form_event("incomplete_or_repeat_submission_error")
        return render template: "errors/incomplete_submission", locals: { form: @form, current_context: }
      end

      begin
        submission_reference = FormSubmissionService.call(current_context:,
                                                          email_confirmation_input: confirmation_input,
                                                          mode:).submit

        current_context.save_submission_details(submission_reference, requested_email_confirmation)

        redirect_to :form_submitted
      rescue FormSubmissionService::ConfirmationEmailToAddressError
        confirmation_input.errors.add(:confirmation_email_address, :invalid_email)
        setup_email_confirmation_page(confirmation_input)
        render template: "forms/email_confirmation/show", status: :unprocessable_content
      end
    rescue StandardError => e
      log_rescued_exception(e)

      render "errors/submission_error", status: :internal_server_error
    end

  private

    def email_confirmation_input_params
      params.fetch(:email_confirmation_input, ActionController::Parameters.new)
            .permit(:send_confirmation, :confirmation_email_address, :confirmation_email_reference)
    end

    def email_confirmation_input
      @email_confirmation_input ||= begin
        attributes = stored_email_confirmation_input || email_confirmation_input_params.to_h
        if attributes.blank?
          attributes = { "send_confirmation" => "skip_confirmation" }
        end

        EmailConfirmationInput.new(attributes)
      end
    end

    def setup_check_your_answers
      @back_link = email_confirmation_path(form_id: current_context.form.id, form_slug: current_context.form.form_slug)
      @steps = current_context.completed_steps
      @form_submit_path = form_submit_answers_path

      unless mode.preview?
        EventLogger.log_form_event("check_answers")
      end
    end

    def email_confirmation_summary
      case email_confirmation_input.send_confirmation
      when "send_email_with_answers"
        t("form.check_your_answers.email_confirmation_with_answers_summary", email: email_confirmation_input.confirmation_email_address)
      when "send_email"
        t("form.check_your_answers.email_confirmation_reference_only_summary", email: email_confirmation_input.confirmation_email_address)
      else
        t("form.check_your_answers.email_confirmation_none_summary")
      end
    end

    def setup_email_confirmation_page(confirmation_input)
      @email_confirmation_input = confirmation_input
      @save_path = form_save_email_confirmation_path
      @support_details = current_context.support_details
      previous_step = current_context.previous_step(CheckYourAnswersStep::CHECK_YOUR_ANSWERS_PAGE_SLUG)
      @back_link = if previous_step&.repeatable?
                     add_another_answer_path(form_id: current_context.form.id, form_slug: current_context.form.form_slug, page_slug: previous_step.id)
                   elsif previous_step.present?
                     form_page_path(current_context.form.id, current_context.form.form_slug, previous_step.id)
                   end
    end
  end
end
