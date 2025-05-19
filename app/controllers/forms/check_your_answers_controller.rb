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

      setup_check_your_answers
      email_confirmation_input = EmailConfirmationInput.new

      @support_details = current_context.support_details

      render template: "forms/check_your_answers/show", locals: { email_confirmation_input: }
    end

    def submit_answers
      @support_details = current_context.support_details
      email_confirmation_input = EmailConfirmationInput.new(email_confirmation_input_params)
      requested_email_confirmation = email_confirmation_input.send_confirmation == "send_email"

      unless email_confirmation_input.valid?
        setup_check_your_answers

        return render template: "forms/check_your_answers/show", locals: { email_confirmation_input: }, status: :unprocessable_entity
      end

      return redirect_to error_repeat_submission_path(current_form.id) if current_context.form_submitted?

      unless current_context.can_visit?(CheckYourAnswersStep::CHECK_YOUR_ANSWERS_PAGE_SLUG)
        EventLogger.log_form_event("incomplete_or_repeat_submission_error")
        return render template: "errors/incomplete_submission", locals: { current_form:, current_context: }
      end

      submission_reference = FormSubmissionService.call(current_context:,
                                                        email_confirmation_input:,
                                                        mode:).submit

      current_context.save_submission_details(submission_reference, requested_email_confirmation)

      redirect_to :form_submitted
    rescue StandardError => e
      log_rescued_exception(e)

      render "errors/submission_error", status: :internal_server_error
    end

  private

    def page_to_row(page)
      question_name = page.question.question_text_for_check_your_answers
      {
        key: { text: helpers.sanitize(question_name) },
        value: { text: page.show_answer },
        actions: [{ text: I18n.t("govuk_components.govuk_summary_list.change"), href: change_link(page), visually_hidden_text: helpers.strip_tags(question_name) }],
      }
    end

    def change_link(page)
      return change_add_another_answer_path(page.form_id, page.form_slug, page.page_id) if page.repeatable? && page.show_answer.present?

      form_change_answer_path(page.form_id, page.form_slug, page.page_id)
    end

    def check_your_answers_rows
      current_context.completed_steps.map { |page| page_to_row(page) }
    end

    def answers_need_full_width
      @full_width = current_context.completed_steps.any? { |step| step.question.has_long_answer? }
    end

    def email_confirmation_input_params
      params.require(:email_confirmation_input).permit(:send_confirmation, :confirmation_email_address, :confirmation_email_reference)
    end

    def setup_check_your_answers
      @back_link = back_link
      @rows = check_your_answers_rows
      @form_submit_path = form_submit_answers_path

      unless mode.preview?
        EventLogger.log_form_event("check_answers")
      end

      answers_need_full_width
    end

    def back_link
      previous_step = current_context.previous_step(CheckYourAnswersStep::CHECK_YOUR_ANSWERS_PAGE_SLUG)

      if previous_step.present?
        previous_step.repeatable? ? add_another_answer_path(form_id: current_context.form.id, form_slug: current_context.form.form_slug, page_slug: previous_step.page_slug) : form_page_path(current_context.form.id, current_context.form.form_slug, previous_step.page_id)
      end
    end
  end
end
