module Flow
  ##
  # This class represents the journey taken by a form filler through a form.
  #
  # For a simple form (with no routing) there is only one possible set of
  # steps that a form filler can take, but for a form with routing there
  # may be some pages that the form filler never sees.
  #
  # Journey#completed_steps is an array of the steps that the form filler has
  # visited so far in the form, in the order defined by the form. If their
  # answer to a question page step causes a routing rule to be applied, for
  # instance by skipping over the next two questions, only the questions in the
  # resulting route are included.
  #
  # Note: the completed_steps array is ordered, from start to last step
  # answered; if the form filler has not yet visited the forms first page the
  # array will be empty.

  class Journey
    include Enumerable

    attr_reader :completed_steps

    def initialize(form_context:, step_factory:)
      @form_context = form_context
      @step_factory = step_factory
      generate_completed_steps
    end

  private

    def find_completed_step(page_slug)
      step = @step_factory.create_step(page_slug)

      # A step has been completed if it is a question page that has been answered.
      # We also need to load the answer into the step for next_page_with_routing to give the correct result.
      step.load_from_context(@form_context) unless @form_context.get_stored_answer(step).nil?
    rescue ActiveModel::UnknownAttributeError, ArgumentError
      @form_context.clear_stored_answer(step)
      nil
    end

    def generate_completed_steps
      @completed_steps = []
      current_step = find_completed_step(:_start)

      while current_step
        next_page_slug = current_step.next_page_slug_after_routing

        # Prevent infinite loop if a route goes back on itself
        break if @completed_steps.map(&:page_slug).include?(next_page_slug)

        @completed_steps << current_step

        break if next_page_slug.nil?

        current_step = find_completed_step(next_page_slug)
      end
    end
  end
end
