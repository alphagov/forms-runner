module Forms
  class CheckYourAnswersController < BaseController
    def show
      return redirect_to form_page_path(current_context.form, current_context.form_slug, current_context.next_page_slug) unless current_context.can_visit?("check_your_answers")

      previous_step = current_context.previous_step("check_your_answers")
      @back_link = form_page_path(current_context.form, current_context.form_slug, previous_step)
      @rows = check_your_answers_rows
      unless preview?
        EventLogger.log_form_event(current_context, request, "check_answers")
      end
    end

  private

    def page_to_row(page)
      question_name = page.question_short_name.presence || page.question_text
      {
        key: { text: question_name },
        value: { text: page.show_answer },
        actions: [{ href: form_change_answer_path(page.form_id, page.form_slug, page.page_id), visually_hidden_text: question_name }],
      }
    end

    def check_your_answers_rows
      current_context.steps.map { |page| page_to_row(page) }
    end
  end
end
