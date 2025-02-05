module Forms
  class RemoveAnswerController < PageController
    def show
      @remove_input = RemoveInput.new
    end

    def delete
      @remove_input = RemoveInput.new(remove_input_params)

      if @remove_input.invalid?
        return render :show, status: :unprocessable_entity
      end

      if @remove_input.remove?
        remove_answer
      end

      redirect_to next_page_after_removing
    end

  private

    def remove_input_params
      params.require(:remove_input).permit(:remove)
    end

    def remove_answer
      @step.remove_answer(@step.answer_index)
      @current_context.save_step(@step)
    end

    def next_page_after_removing
      if @step.question.is_optional? && @step.show_answer.blank?
        form_page_path(@step.form_id, @step.form_slug, @step.page_slug, changing_existing_answer:)
      else
        add_another_answer_path(@step.form_id, @step.form_slug, @step.page_slug, changing_existing_answer:)
      end
    end
  end
end
