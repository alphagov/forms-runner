class RepeatableStep < Step
  include ActionView::Helpers::SanitizeHelper
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::OutputSafetyHelper

  attr_accessor :answer_id, :questions

  def initialize(...)
    super
    @questions = []
  end

  def repeatable?
    true
  end

  def parent_question
    Step.instance_method(:question).bind(self).call
  end

  def save_to_context(form_context)
    form_context.save_step(self, @questions.map(&:serializable_hash))
    self
  end

  def load_from_context(form_context)
    question_attrs = form_context.get_stored_answer(self)

    unless question_attrs.is_a?(Array)
      raise ArgumentError
    end

    @questions = question_attrs.map do |attrs|
      q = parent_question.dup
      q.assign_attributes(attrs || {})
      q
    end

    self
  end

  def question
    if questions.blank?
      add_blank_answer
    end

    if next_answer_id == answer_id
      return add_blank_answer
    end

    if answer_id && answer_id <= @questions.count
      return questions[answer_id - 1]
    end

    questions.first
  end

  def next_answer_id
    questions.length + 1
  end

  def show_answer
    if questions.present?
      safe_join(
        questions.map.with_index(1) do |question, index|
          content_tag(:p, sanitize("#{index}. #{question.show_answer}"))
        end,
      )
    end
  end

private

  def add_blank_answer
    questions << parent_question.dup
    questions[answer_id - 1]
  end
end
