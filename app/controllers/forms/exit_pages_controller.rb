module Forms
  class ExitPagesController < PageController
    def show
      return redirect_to form_page_path(current_form.id, current_form.form_slug, current_context.next_page_slug) unless current_context.can_visit?(@step.page_slug)

      @back_link = form_page_path(current_form.id, current_form.form_slug, @step.page_slug)
      @condition = @step.routing_conditions.first
    end
  end
end
