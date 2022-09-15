module Forms
  class PageController < FormController
    before_action :prepare_step, :changing_existing_answer, :set_privacy_policy_url

    def show
      path_to_redirect = params[:preview] ? preview_form_page_path(@step.form_id, current_context.next_page_slug) : form_page_path(@step.form_id, current_context.next_page_slug)
      redirect_to path_to_redirect unless current_context.can_visit?(@step.page_slug)
      back_link(@step.page_slug)
      @save_path = params[:preview] ? preview_save_form_page_path(@step.form_id, @step.id, changing_existing_answer: @changing_existing_answer) : save_form_page_path(@step.form_id, @step.id, changing_existing_answer: @changing_existing_answer)
    end

    def save
      page_params = params.require(:question).permit(*@step.params)
      @step.update!(page_params)

      if current_context.save_step(@step)
        unless params[:preview]
          log_page_save(@step, request, changing_existing_answer)
        end
        redirect_to next_page(params[:preview])
      else
        render :show
      end
    end

  private

    def prepare_step
      page_slug = params.require(:page_slug)
      @step = current_context.find_or_create(page_slug)
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
        @back_link = changing_answer_path(current_context)
      elsif previous_step
        @back_link = previous_step_path(previous_step)
      end
    end

    def changing_answer_path(context)
      params[:preview] ? preview_check_your_answers_path(form_id: context.form) : check_your_answers_path(form_id: context.form)
    end

    def previous_step_path(previous_step)
      params[:preview] ? preview_form_page_path(@step.form_id, previous_step) : form_page_path(@step.form_id, previous_step)
    end

    def next_page(preview)
      if @changing_existing_answer
        if preview
          preview_check_your_answers_path(current_context.form)
        else
          check_your_answers_path(current_context.form)
        end
      elsif preview
        preview_form_page_path(@step.form_id, @step.next_page_slug)
      else
        form_page_path(@step.form_id, @step.next_page_slug)
      end
    end

    def is_starting_form(step)
      current_context.form_start_page == step.id
    end

    def log_page_save(step, request, changing_existing_answer)
      log_event = if changing_existing_answer
                    "change_answer_page_save"
                  elsif is_starting_form(step)
                    "first_page_save"
                  else
                    "page_save"
                  end

      EventLogger.log_page_event(current_context, step, request, log_event)
    end

    def set_privacy_policy_url
      @privacy_policy_url = current_context.privacy_policy_url
    end
  end
end
