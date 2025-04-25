module Forms
  class ReviewFileController < PageController
    before_action :redirect_if_not_answered_file_question

    def show
      back_link(@step.page_slug)
      @remove_file_confirmation_url = remove_file_confirmation_path(form_id: @step.form_id, form_slug: @step.form_slug, page_slug: @step.page_slug, changing_existing_answer:)
      @continue_url = review_file_continue_path(form_id: @step.form_id, form_slug: @step.form_slug, page_slug: @step.page_slug, changing_existing_answer:)
    end

    def continue
      redirect_to next_page
    end
  end
end
