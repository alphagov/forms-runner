module Forms
  class PageController < BaseController
    before_action :prepare_step, :changing_existing_answer

    def show
      redirect_to form_page_path(@step.form_id, @step.form_slug, current_context.next_page_slug) unless current_context.can_visit?(@step.page_slug)
      back_link(@step.page_slug)
    end

    def save
      page_params = params.require(:question).permit(*@step.params)
      @step.update!(page_params)

      if current_context.save_step(@step)
        unless preview?
          log_page_save(@step, request, changing_existing_answer, page_params)
        end
        redirect_to next_page
      else
        render :show
      end
    end

  private

    def prepare_step
      page_slug = params.require(:page_slug)
      @step = current_context.find_or_create(page_slug)

      @support_details = current_context.support_details
    rescue StepFactory::PageNotFoundError => e
      Sentry.capture_exception(e)
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
        @back_link = form_page_path(@step.form_id, @step.form_slug, previous_step)
      end
    end

    def next_page
      if @changing_existing_answer
        check_your_answers_path(form_id: current_context.form, form_slug: current_context.form_slug)
      else
        form_page_path(@step.form_id, @step.form_slug, @step.next_page_slug)
      end
    end

    def is_starting_form(step)
      current_context.form_start_page == step.id
    end

    def log_page_save(step, request, changing_answer, answers)
      EventLogger.log_page_event(current_context, step, request, log_event(changing_answer, step), skipped_question?(answers))
    end

    def log_event(changing_answer, step)
      page_optional = @step.question.is_optional? ? "optional" : "page"

      if changing_answer
        "change_answer_#{page_optional}_save"
      elsif is_starting_form(step)
        "first_#{page_optional}_save"
      else
        "#{page_optional}_save"
      end
    end

    def skipped_question?(answers)
      @step.question.is_optional? ? answers.each_value.map.none?(&:present?) : nil
    end
  end
end
