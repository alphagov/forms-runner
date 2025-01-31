module Forms
  class ReviewFileController < PageController
    before_action :redirect_if_not_answered_file_question

    def show
      back_link(@step.page_slug)
      @remove_file_url = remove_file_path(form_id: @step.form_id, form_slug: @step.form_slug, page_slug: @step.page_slug, changing_existing_answer:)
      @continue_url = review_file_continue_path(form_id: @step.form_id, form_slug: @step.form_slug, page_slug: @step.page_slug, changing_existing_answer:)
    end

    def delete
      @step.question.delete_from_s3
      current_context.clear_stored_answer(@step)

      redirect_to redirect_after_delete_path, success: t("banner.success.file_removed")
    end

    def continue
      redirect_to next_page
    end

  private

    def redirect_if_not_answered_file_question
      unless @step.question.is_a?(Question::File) && @step.question.file_uploaded?
        redirect_to form_page_path(@step.form_id, @step.form_slug, @step.page_slug)
      end
    end

    def redirect_after_delete_path
      if changing_existing_answer
        return form_change_answer_path(form_id: @step.form_id, form_slug: @step.form_slug, page_slug: @step.page_slug)
      end

      form_page_path(form_id: @step.form_id, form_slug: @step.form_slug, page_slug: @step.page_slug)
    end
  end
end
