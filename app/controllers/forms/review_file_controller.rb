module Forms
  class ReviewFileController < PageController
    before_action :redirect_if_not_answered_file_question

    def show
      back_link(@step.page_slug)
      @continue_url = review_file_continue_path(form_id: @step.form_id, form_slug: @step.form_slug, page_slug: @step.page_slug)
    end

    def delete; end

    def continue
      redirect_to next_page
    end

  private

    def redirect_if_not_answered_file_question
      unless @step.question.is_a?(Question::File) && @step.question.file_uploaded?
        redirect_to form_page_path(@step.form_id, @step.form_slug, @step.page_slug)
      end
    end
  end
end
