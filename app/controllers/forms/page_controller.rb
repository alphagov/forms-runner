module Forms
  class PageController < BaseController
    before_action :prepare_step, :set_logging_attributes, :changing_existing_answer, :check_goto_page_before_routing_page

    def set_logging_attributes
      super
      CurrentLoggingAttributes.question_number = @step.page_number if @step&.page_number
    end

    def show
      # redirect_to form_page_path(@step.form_id, @step.form_slug, current_context.next_page_slug) unless current_context.can_visit?(@step.page_slug)
      back_link(@step.page_slug)
      setup_instance_vars_for_view
    end

    def save
      page_params = params.require(:question).permit(*@step.params)
      @step.update!(page_params)

      if current_context.save_step(@step)
        current_context.clear_submission_details if is_first_page?

        unless mode.preview?
          LogEventService.new(current_context, @step, request, changing_existing_answer, page_params).log_page_save
        end

        redirect_to next_page
      else
        setup_instance_vars_for_view
        render :show, status: :unprocessable_entity
      end
    end

  private

    def prepare_step
      page_slug = params.require(:page_slug)
      @step = current_context.find_or_create(page_slug)

      if @step.respond_to?(:answer_index)
        @step.answer_index = answer_index
      end

      @support_details = current_context.support_details
    end

    def answer_index
      params.fetch(:answer_index, 1).to_i
    end

    def setup_instance_vars_for_view
      @is_question = true
      @question_edit_link = "#{Settings.forms_admin.base_url}/forms/#{@step.form_id}/pages/#{@step.page_slug}/edit/question"
      @save_url = save_url
    end

    def changing_existing_answer
      @changing_existing_answer = ActiveModel::Type::Boolean.new.cast(params[:changing_existing_answer])
    end

    def back_link(page_slug)
      previous_step = current_context.previous_step(page_slug)

      if changing_existing_answer
        @back_link = check_your_answers_path(form_id: current_context.form.id)
      elsif previous_step
        @back_link = previous_step.repeatable? ? add_another_answer_path(form_id: current_context.form.id, form_slug: current_context.form.form_slug, page_slug: previous_step.page_slug) : form_page_path(@step.form_id, @step.form_slug, previous_step.page_id)
      end
    end

    def next_page
      if changing_existing_answer
        return next_step_changing
      end

      next_step_path
    end

    def next_step_path
      if should_show_add_another?(@step)
        return add_another_answer_path(form_id: @step.form_id, form_slug: @step.form_slug, page_slug: @step.page_slug)
      end

      next_step_in_form_path
    end

    def next_step_changing
      if should_show_add_another?(@step)
        return change_add_another_answer_path(form_id: @step.form_id, form_slug: @step.form_slug, page_slug: @step.page_slug)
      end

      check_answers_path
    end

    def next_step_in_form_path
      form_page_path(@step.form_id, @step.form_slug, @step.next_page_slug_after_routing)
    end

    def check_answers_path
      check_your_answers_path(form_id: current_context.form.id, form_slug: current_context.form.form_slug)
    end

    def should_show_add_another?(step)
      step.repeatable? && !step.skipped?
    end

    def check_goto_page_before_routing_page
      return unless @step.routing_conditions.filter { |condition| condition.validation_errors.filter { |error| error.name == "cannot_have_goto_page_before_routing_page" }.any? }.any?

      EventLogger.log_page_event("goto_page_before_routing_page_error", @step.question.question_text, nil)
      render template: "errors/goto_page_before_routing_page", locals: { link_url: "#{Settings.forms_admin.base_url}/forms/#{@step.form_id}/pages/#{@step.page_slug}/conditions/#{@step.routing_conditions.first.id}", question_number: @step.page_number }, status: :unprocessable_entity
    end

    def is_first_page?
      current_context.form.start_page == @step.id
    end

    def save_url
      save_form_page_path(@step.form_id, @step.form_slug, @step.id, changing_existing_answer: @changing_existing_answer, answer_index:)
    end
  end
end
