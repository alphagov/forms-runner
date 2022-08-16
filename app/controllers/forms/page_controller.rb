module Forms
  class PageController < FormController
    before_action :prepare_step, :changing_existing_answer

    def show
      redirect_to form_page_path(@step.form_id, current_context.next_page_slug) unless current_context.can_visit?(@step.page_slug)
      back_link(@step.page_slug)
    end

    def submit
      page_params = params.require(:question).permit(*@step.params)
      @step.update!(page_params)

      if current_context.save_step(@step)
        redirect_to next_page
      else
        render :show
      end
    end

  private

    def prepare_step
      page_slug = params.require(:page_slug)
      @step = current_context.find_or_create(page_slug)
    rescue StepFactory::PageNotFoundError
      render "errors/not_found", status: :not_found
    end

    def changing_existing_answer
      @changing_existing_answer = ActiveModel::Type::Boolean.new.cast(params[:changing_existing_answer])
    end

    def back_link(page_slug)
      previous_step = current_context.previous_step(page_slug)
      if @changing_existing_answer
        @back_link = check_your_answers_path(form_id: current_context.form)
      elsif previous_step
        @back_link = form_page_path(@step.form_id, previous_step)
      end
    end

    def next_page
      if @changing_existing_answer
        check_your_answers_path(current_context.form)
      else
        form_page_path(@step.form_id, @step.next_page_slug)
      end
    end
  end
end
