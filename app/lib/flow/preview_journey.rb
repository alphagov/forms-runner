module Flow
  class PreviewJourney < Journey
    private

    def find_existing_step(page_slug)
      return nil if page_slug == CheckYourAnswersStep::CHECK_YOUR_ANSWERS_PAGE_SLUG

      step = @step_factory.create_step(page_slug)
      step.load_from_context(@form_context) unless @form_context.get_stored_answer(step).nil?
      step
    rescue ActiveModel::UnknownAttributeError, ArgumentError
      @form_context.clear_stored_answer(step)
      nil
    end
  end
end
