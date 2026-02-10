module Forms
  class GetACopyOfYourAnswersController < BaseController
    before_action :prepare_step

    def show
      @back_link = back_link
      get_a_copy_of_your_answers_input = @step.question

      render template: "forms/get_a_copy_of_your_answers/show", locals: { get_a_copy_of_your_answers_input: }
    end

    def save
      @step.assign_question_attributes(get_a_copy_of_your_answers_input_params)

      if current_context.save_step(@step, locale:)
        if @step.question.get_a_copy_of_your_answers == "yes"
          # TODO: Do One Login stuff here
        end
        redirect_to check_your_answers_path
      else
        @back_link = back_link
        get_a_copy_of_your_answers_input = @step.question
        render template: "forms/get_a_copy_of_your_answers/show", locals: { get_a_copy_of_your_answers_input: }, status: :unprocessable_content
      end
    end

  private

    def get_a_copy_of_your_answers_input_params
      params.require(:question_get_a_copy_of_your_answers).permit(:get_a_copy_of_your_answers)
    end

    def back_link
      previous_step = current_context.previous_step(GetACopyOfYourAnswersStep::GET_A_COPY_OF_YOUR_ANSWERS_PAGE_SLUG)

      if previous_step.present?
        previous_step.repeatable? ? add_another_answer_path(form_id: current_context.form.id, form_slug: current_context.form.form_slug, page_slug: previous_step.id) : form_page_path(current_context.form.id, current_context.form.form_slug, previous_step.id)
      end
    end

    def prepare_step
      page_slug = GetACopyOfYourAnswersStep::GET_A_COPY_OF_YOUR_ANSWERS_PAGE_SLUG

      @step = current_context.find_or_create(page_slug)
    end
  end
end
