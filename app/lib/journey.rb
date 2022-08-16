class Journey
  include Enumerable

  attr_reader :completed_steps

  def initialize(form_context:, step_factory:)
    @form_context = form_context
    @step_factory = step_factory
    generate_completed_steps
  end

private

  def find_existing_step(page_slug)
    step = @step_factory.create_step(page_slug)
    step.load_from_context(@form_context) unless @form_context.get_stored_answer(step).nil?
  end

  def generate_completed_steps
    @completed_steps = []
    current_step = find_existing_step(:_start)

    while current_step
      @completed_steps << current_step
      next_page_slug = current_step.next_page_slug

      break if next_page_slug.nil?

      current_step = find_existing_step(next_page_slug)
    end
  end
end
