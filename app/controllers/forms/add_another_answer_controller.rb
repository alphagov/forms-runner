module Forms
  class AddAnotherAnswerController < PageController
    def show
    end

    def save
      if params[:add_another] == "yes"
        debugger
      elsif params[:add_another] == "no"
        redirect_to next_page
      end
    end

  private

    def next_page
      form_page_path(@step.form_id, @step.form_slug, @step.next_page_slug)
    end
  end
end
