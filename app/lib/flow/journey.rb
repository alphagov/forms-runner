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
    attr_reader :completed_steps

    def initialize(form_context:, step_factory:)
      @form_context = form_context
      @step_factory = step_factory
      @completed_steps = generate_completed_steps
    end

  private

    def step_is_completed?(question_page_step)
      # A step has been completed if it is a question page that has been answered.
      question_page_step.question.answered?
    end

    def generate_completed_steps
      each_step_with_routing.take_while do |step|
        step_is_completed?(step)
      end
    end

    def each_step_with_routing
      current_step = @step_factory.create_step(:_start)
      visited_page_slugs = []

      Enumerator.new do |yielder|
        loop do
          break if current_step.nil?
          break if current_step.is_a? CheckYourAnswersStep # CheckYourAnswers step signals end of steps

          # We need to load the answer into the step for next_page_with_routing to give the correct result.
          current_step = safe_load_from_context(current_step)

          next_page_slug = current_step.next_page_slug_after_routing

          # Prevent infinite loop if a route goes back on itself
          break if visited_page_slugs.include?(next_page_slug)

          yielder << current_step
          visited_page_slugs << current_step.page_slug

          break if next_page_slug.nil?

          current_step = @step_factory.create_step(next_page_slug)
        end
      end
    end

    def safe_load_from_context(step)
      return step unless step.respond_to? :load_from_context # step may be a CheckYourAnswersStep without load_from_context method

      original_step = step.deep_dup # load_from_context method for RepeatableStep can fail with data half loaded

      begin
        step.load_from_context(@form_context)
      rescue ActiveModel::UnknownAttributeError, ArgumentError
        original_step
      end
    end
  end
end
