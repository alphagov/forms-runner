module Forms
  class CheckYourAnswersController < FormController
    before_action :set_privacy_policy_url

    def show
      path_to_redirect = params[:preview] ? preview_form_page_path(current_context.form, current_context.next_page_slug) : form_page_path(current_context.form, current_context.next_page_slug)
      return redirect_to path_to_redirect unless current_context.can_visit?("check_your_answers")

      previous_step = current_context.previous_step("check_your_answers")
      @back_link = params[:preview] ? preview_form_page_path(current_context.form, previous_step) : form_page_path(current_context.form, previous_step)
      @rows = check_your_answers_rows
      @submit_answers_path = params[:preview] ? preview_form_submit_answers_path : form_submit_answers_path
      unless params[:preview]
        EventLogger.log_form_event(current_context, request, "check_answers")
      end
    end

  private

    def page_to_row(page)
      change_answer_path = params[:preview] ? preview_form_change_answer_path(page.form_id, page.page_id) : form_change_answer_path(page.form_id, page.page_id)
      question_name = page.question_short_name.presence || page.question_text
      {
        key: { text: question_name },
        value: { text: page.show_answer },
        actions: [{ href: change_answer_path, visually_hidden_text: question_name }],
      }
    end

    def check_your_answers_rows
      current_context.steps.map { |page| page_to_row(page) }
    end

    def set_privacy_policy_url
      @privacy_policy_url = current_context.privacy_policy_url
    end
  end
end
