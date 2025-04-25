module Forms
  class PageController < BaseController
    before_action :prepare_step, :set_request_logging_attributes, :changing_existing_answer, :check_goto_page_routing_error

    def set_request_logging_attributes
      super
      CurrentRequestLoggingAttributes.question_number = @step.page_number if @step&.page_number
      CurrentRequestLoggingAttributes.answer_type = @step&.page&.answer_type if @step&.page&.answer_type
    end

    def show
      return redirect_to form_page_path(@step.form_id, @step.form_slug, current_context.next_page_slug) unless current_context.can_visit?(@step.page_slug)
      return redirect_to review_file_page if answered_file_question?

      back_link(@step.page_slug)
      setup_instance_vars_for_view
    end

    def save
      page_params = params.fetch(:question, {}).permit(*@step.params)
      @step.update!(page_params)

      if current_context.save_step(@step)
        current_context.clear_submission_details if is_first_page?

        unless mode.preview?
          LogEventService.new(current_context, @step, request, changing_existing_answer, page_params).log_page_save
        end

        redirect_post_save
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

    def redirect_post_save
      return redirect_to review_file_page, success: t("banner.success.file_uploaded") if answered_file_question?
      return redirect_to exit_page_path(form_id: @step.form_id, form_slug: @step.form_slug, page_slug: @step.page_slug) if @step.exit_page_condition_matches?

      redirect_to next_page
    end

    def redirect_if_not_answered_file_question
      unless @step.question.is_a?(Question::File) && @step.question.file_uploaded?
        redirect_to form_page_path(@step.form_id, @step.form_slug, @step.page_slug)
      end
    end

    def answered_file_question?
      @step.question.is_a?(Question::File) && @step.question.file_uploaded?
    end

    def review_file_page
      review_file_path(form_id: @step.form_id, form_slug: @step.form_slug, page_slug: @step.page_slug, changing_existing_answer:)
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

    def check_goto_page_routing_error
      return if @step.conditions_with_goto_errors.blank?

      first_condition_with_error = @step.conditions_with_goto_errors.first

      first_goto_error_name = first_condition_with_error.validation_errors.find { |error|
        Step::GOTO_PAGE_ERROR_NAMES.include?(error.name)
      }.name

      event_name = if first_goto_error_name == "cannot_have_goto_page_before_routing_page"
                     "goto_page_before_routing_page_error"
                   else
                     "goto_page_doesnt_exist_error"
                   end

      EventLogger.log_page_event(event_name, @step.question.question_text, nil)

      routes_page_id = first_condition_with_error.check_page_id
      routes_page = @current_context.find_or_create(routes_page_id)

      render template: "errors/goto_page_routing_error", locals: {
        error_name: first_goto_error_name,
        link_url: admin_edit_condition_url(@step.form_id, routes_page_id),
        question_number: routes_page.page_number,
      }, status: :unprocessable_entity
    end

    def admin_edit_condition_url(form_id, page_id)
      "#{Settings.forms_admin.base_url}/forms/#{form_id}/pages/#{page_id}/routes"
    end

    def is_first_page?
      current_context.form.start_page == @step.id
    end

    def save_url
      save_form_page_path(@step.form_id, @step.form_slug, @step.id, changing_existing_answer: @changing_existing_answer, answer_index:)
    end
  end
end
