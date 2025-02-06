module Forms
  class RemoveFileController < PageController
    before_action :redirect_if_not_answered_file_question

    def show
      setup_urls
      @remove_input = RemoveInput.new
    end

    def destroy
      @remove_input = RemoveInput.new(remove_input_params)

      if @remove_input.invalid?
        setup_urls
        return render :show, status: :unprocessable_entity
      end

      if @remove_input.remove?
        @step.question.delete_from_s3
        current_context.clear_stored_answer(@step)
        return redirect_to redirect_after_delete_path, success: t("banner.success.file_removed")
      end

      redirect_to review_file_path(form_id: @step.form_id, form_slug: @step.form_slug, page_slug: @step.page_slug, changing_existing_answer:)
    end

  private

    def remove_input_params
      params.require(:remove_input).permit(:remove)
    end

    def redirect_after_delete_path
      if changing_existing_answer
        return form_change_answer_path(form_id: @step.form_id, form_slug: @step.form_slug, page_slug: @step.page_slug)
      end

      form_page_path(form_id: @step.form_id, form_slug: @step.form_slug, page_slug: @step.page_slug)
    end

    def setup_urls
      @back_link = review_file_path(form_id: @step.form_id, form_slug: @step.form_slug, page_slug: @step.page_slug, changing_existing_answer:)
      @remove_file_url = remove_file_path(form_id: @step.form_id, form_slug: @step.form_slug, page_slug: @step.page_slug, changing_existing_answer:)
    end
  end
end
