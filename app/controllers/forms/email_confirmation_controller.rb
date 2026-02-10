module Forms
  class EmailConfirmationController < BaseController
    def show
      return redirect_to form_page_path(current_context.form.id, current_context.form.form_slug, current_context.next_page_slug, nil) unless current_context.can_visit?(CheckYourAnswersStep::CHECK_YOUR_ANSWERS_PAGE_SLUG)

      store_govuk_one_login_return_path
      @back_link = back_link
      @signed_in_email = session[:govuk_one_login_email]
      @save_path = form_save_email_confirmation_path
      @email_confirmation_input = build_email_confirmation_input
      @support_details = current_context.support_details
    end

    def save
      @signed_in_email = session[:govuk_one_login_email]
      @back_link = back_link
      @save_path = form_save_email_confirmation_path
      @support_details = current_context.support_details
      @email_confirmation_input = EmailConfirmationInput.new(email_confirmation_input_params)

      if @email_confirmation_input.send_confirmation == "send_email_with_answers" && @signed_in_email.blank?
        @email_confirmation_input.errors.add(:send_confirmation, :one_login_required)
      end

      if @email_confirmation_input.send_confirmation == "send_email_with_answers" && @signed_in_email.present?
        @email_confirmation_input.confirmation_email_address = @signed_in_email
      end

      if @email_confirmation_input.valid? && @email_confirmation_input.errors.empty?
        save_email_confirmation_input(
          send_confirmation: @email_confirmation_input.send_confirmation,
          confirmation_email_address: @email_confirmation_input.confirmation_email_address,
          confirmation_email_reference: @email_confirmation_input.confirmation_email_reference,
        )
        return redirect_to check_your_answers_path(form_id: @form.id, form_slug: @form.form_slug)
      end

      render :show, status: :unprocessable_content
    end

  private

    def email_confirmation_input_params
      params.fetch(:email_confirmation_input, ActionController::Parameters.new)
            .permit(:send_confirmation, :confirmation_email_address, :confirmation_email_reference)
    end

    def build_email_confirmation_input
      stored_values = stored_email_confirmation_input
      return EmailConfirmationInput.new(stored_values) if stored_values.present?

      EmailConfirmationInput.new(send_confirmation: "skip_confirmation")
    end

    def store_govuk_one_login_return_path
      session[:govuk_one_login_last_mode] = mode.to_s
      session[:govuk_one_login_last_form_id] = current_context.form.id
      session[:govuk_one_login_last_form_slug] = current_context.form.form_slug
      session[:govuk_one_login_last_locale] = locale_param
      session[:govuk_one_login_return_to] = "email_confirmation"
    end

    def back_link
      previous_step = current_context.previous_step(CheckYourAnswersStep::CHECK_YOUR_ANSWERS_PAGE_SLUG)
      return nil unless previous_step

      previous_step.repeatable? ? add_another_answer_path(form_id: current_context.form.id, form_slug: current_context.form.form_slug, page_slug: previous_step.id) : form_page_path(current_context.form.id, current_context.form.form_slug, previous_step.id)
    end
  end
end
