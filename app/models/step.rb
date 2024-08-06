class Step
  attr_accessor :page_id, :form_id, :form_slug, :question
  attr_reader :is_repeatable, :next_page_slug, :page_slug, :page_number, :routing_conditions

  def initialize(question:, page:, form_id:, form_slug:, next_page_slug:, page_slug:)
    @is_repeatable = page.is_repeatable
    @question = question
    @page_id = page.id
    @page_slug = page_slug
    @form_id = form_id
    @form_slug = form_slug
    @next_page_slug = next_page_slug
    @page_number = page.position
    @routing_conditions = page.respond_to?(:routing_conditions) ? page.routing_conditions : []
  end

  alias_attribute :id, :page_id

  def ==(other)
    other.class == self.class && other.state == state
  end

  def repeatable?
    is_repeatable
  end

  def state
    instance_variables.map { |variable| instance_variable_get variable }
  end

  def save_to_context(form_context)
    form_context.save_step(self, @question.serializable_hash)
    self
  end

  def load_from_context(form_context)
    attrs = form_context.get_stored_answer(self)
    @question.assign_attributes(attrs || {})
    self
  end

  def update!(params)
    @question.assign_attributes(params)
    @question.valid?
  end

  def params
    @question.attribute_names.concat([selection: []])
  end

  def valid?
    @question.valid?
  end

  def clear_errors
    @question.errors.clear
  end

  def show_answer
    @question.show_answer
  end

  def show_answer_in_email
    @question.show_answer_in_email
  end

  def question_text
    @question.question_text
  end

  def hint_text
    @question.hint_text
  end

  def answer_settings
    @question.answer_settings
  end

  def end_page?
    next_page_slug.nil?
  end

  def next_page_slug_after_routing
    if routing_conditions.any? && routing_conditions.first.answer_value == @question.selection
      goto_page_slug
    else
      next_page_slug
    end
  end

  def goto_page_slug
    return nil if routing_conditions.empty?

    condition = routing_conditions.first
    condition.goto_page_id.nil? && condition.skip_to_end ? CheckYourAnswersStep::CHECK_YOUR_ANSWERS_PAGE_SLUG : condition.goto_page_id.to_s
  end
end
