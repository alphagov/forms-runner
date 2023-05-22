module Forms
  class CheckYourAnswersController < BaseController
    def show
      return redirect_to form_page_path(current_context.form.id, current_context.form.form_slug, current_context.next_page_slug) unless current_context.can_visit?(CheckYourAnswersStep::CHECK_YOUR_ANSWERS_PAGE_SLUG)

      previous_step = current_context.previous_step("check_your_answers")
      @back_link = form_page_path(current_context.form.id, current_context.form.form_slug, previous_step)
      @rows = check_your_answers_rows
      @form_submit_path = form_submit_answers_path
      @notify_reference ||= SecureRandom.uuid
      unless mode.preview?
        EventLogger.log_form_event(current_context, request, "check_answers")
      end

      answers_need_full_width
    end

  private

    def page_to_row(page)
      question_name = helpers.question_text_with_optional_suffix(page, @mode)
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
  end
end
