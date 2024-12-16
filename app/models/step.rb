class Step
  attr_accessor :page, :form, :question
  attr_reader :next_page_slug, :page_slug

  GOTO_PAGE_ERROR_NAMES = %w[cannot_have_goto_page_before_routing_page goto_page_doesnt_exist].freeze

  def initialize(form:, page:, question:, next_page_slug:, page_slug:)
    @form = form
    @page = page
    @question = question

    @next_page_slug = next_page_slug
    @page_slug = page_slug
  end

  alias_attribute :id, :page_id

  def form_id
    form&.id
  end

  def form_slug
    form&.form_slug
  end

  def page_id
    page&.id
  end

  def page_number
    page&.position
  end

  def routing_conditions
    page.respond_to?(:routing_conditions) ? page.routing_conditions : []
  end

  def ==(other)
    other.class == self.class && other.state == state
  end

  def state
    instance_variables.map { |variable| instance_variable_get variable }
  end

  def save_to_context(form_context)
    form_context.save_step(self, question.serializable_hash)
    self
  end

  def load_from_context(form_context)
    attrs = form_context.get_stored_answer(self)
    question.assign_attributes(attrs || {})
    self
  end

  def update!(params)
    question.update_answer(params)
    question.valid?
  end

  def params
    question.attribute_names.concat([selection: []])
  end

  delegate :valid?, to: :question

  def clear_errors
    question.errors.clear
  end

  delegate :show_answer, :show_answer_in_email, :show_answer_in_csv, :question_text, :hint_text, :answer_settings, to: :question

  def end_page?
    next_page_slug.nil?
  end

  def next_page_slug_after_routing
    if first_condition_default?
      return goto_condition_page_slug(routing_conditions.first)
    end

    if first_condition_matches?
      return goto_condition_page_slug(routing_conditions.first)
    end

    next_page_slug
  end

  def repeatable?
    false
  end

  def skipped?
    question.is_optional? && question.show_answer.blank?
  end

  def conditions_with_goto_errors
    routing_conditions.filter do |condition|
      condition.validation_errors.any? do |error|
        GOTO_PAGE_ERROR_NAMES.include? error.name
      end
    end
  end

private

  def goto_condition_page_slug(condition)
    if condition.goto_page_id.nil? && condition.skip_to_end
      CheckYourAnswersStep::CHECK_YOUR_ANSWERS_PAGE_SLUG
    else
      condition.goto_page_id.to_s
    end
  end

  def first_condition_matches?
    return unless question.respond_to?(:selection)

    routing_conditions.any? && (routing_conditions.first.answer_value == question.selection)
  end

  def first_condition_default?
    routing_conditions.any? && routing_conditions.first.answer_value.blank?
  end
end
