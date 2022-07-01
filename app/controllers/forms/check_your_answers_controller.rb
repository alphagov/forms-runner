module Forms
  class CheckYourAnswersController < FormController
    def show
      return redirect_to form_page_path(current_context.form, current_context.next_page_slug) unless current_context.complete?

      @back_link = form_page_path(current_context.form, current_context.highest_step.page_slug)
      @rows = check_your_answers_rows
    end

  private

    def page_to_row(page)
      question_name = page.question_short_name.presence || page.question_text
      {
        key: { text: question_name },
        value: { text: page.show_answer },
        actions: [{ href: form_change_answer_path(page.form_id, page.page_id), visually_hidden_text: question_name }],
      }
    end

    def check_your_answers_rows
      current_context.steps.map { |page| page_to_row(page) }
    end
  end
end
