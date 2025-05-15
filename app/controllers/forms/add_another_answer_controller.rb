module Forms
  class AddAnotherAnswerController < PageController
    before_action :redirect_if_not_repeating

    def show
      @rows = rows
      back_link(@step.page_slug)
      @add_another_answer_input = AddAnotherAnswerInput.new
    end

    def save
      @add_another_answer_input = AddAnotherAnswerInput.new(add_another_input_params.merge(max_answers: @step.max_answers?))

      if @add_another_answer_input.invalid?
        @rows = rows
        back_link(@step.page_slug)
        return render :show
      end

      if @add_another_answer_input.add_another_answer?
        redirect_to add_another_path
      else
        redirect_to next_page
      end
    end

  private

    def add_another_path
      if changing_existing_answer
        form_change_answer_path(@step.form_id, @step.form_slug, @step.page_slug, answer_index: @step.next_answer_index)
      else
        form_page_path(@step.form_id, @step.form_slug, @step.page_slug, answer_index: @step.next_answer_index)
      end
    end

    def rows
      @step.questions.map.with_index(1) do |question, answer_index|
        actions = [{ text: t("forms.add_another_answer.rows.change"), href: form_change_answer_path(@step.form_id, @step.form_slug, @step.page_slug, answer_index:), visually_hidden_text: I18n.t("forms.add_another_answer.rows.action_hidden_text", answer_index:) }]

        unless @step.min_answers?
          actions << { text: t("forms.add_another_answer.rows.remove"), href: form_remove_answer_path(@step.form_id, @step.form_slug, @step.page_slug, answer_index:, changing_existing_answer:), visually_hidden_text: I18n.t("forms.add_another_answer.rows.action_hidden_text", answer_index:) }
        end

        {
          key: { text: answer_index },
          value: { text: question.show_answer },
          actions:,
        }
      end
    end

    def should_show_add_another?(_step)
      false
    end

    def add_another_input_params
      params.require(:add_another_answer_input).permit(:add_another_answer)
    end

    def redirect_if_not_repeating
      unless @step.is_a?(RepeatableStep)
        if changing_existing_answer
          redirect_to form_change_answer_path(form_id: @step.form_id, form_slug: @step.form_slug, page_slug: @step.page_slug)
        else
          redirect_to form_page_path(form_id: @step.form_id, form_slug: @step.form_slug, page_slug: @step.page_slug)
        end
      end
    end
  end
end
