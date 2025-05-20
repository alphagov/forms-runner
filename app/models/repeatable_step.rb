class RepeatableStep < Step
  include ActionView::Helpers::SanitizeHelper
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::OutputSafetyHelper

  class AnswerIndexError < IndexError; end

  MAX_ANSWERS = 50

  attr_accessor :answer_index, :questions

  def initialize(...)
    super
    @questions = [@question.dup]
  end

  def repeatable?
    true
  end

  def save_to_store(answer_store)
    answer_store.save_step(self, @questions.map(&:serializable_hash))
    self
  end

  def load_from_store(answer_store)
    question_attrs = answer_store.get_stored_answer(self)

    unless question_attrs.is_a?(Array)
      raise ArgumentError
    end

    @questions = question_attrs.map do |attrs|
      q = @question.dup
      q.assign_attributes(attrs || {})
      q
    end

    self
  end

  def question
    return questions.first if answer_index.blank?

    if questions.length + 1 == answer_index
      return add_blank_answer
    end

    questions.fetch(answer_index - 1)
  rescue IndexError
    raise AnswerIndexError
  end

  def next_answer_index
    questions.length + 1
  end

  def max_answers?
    questions.length >= MAX_ANSWERS
  end

  def valid?
    questions.all?(&:valid?)
  end

  def show_answer
    answers = questions.map(&:show_answer).compact_blank

    if answers.present?
      content_tag(:ol, class: "govuk-list govuk-list--number") do
        safe_join(
          answers.map do |answer|
            content_tag(:li, sanitize(answer))
          end,
        )
      end
    end
  end

  def show_answer_in_email
    if questions.present?
      questions.map.with_index(1) { |question, index|
        "#{index}. #{question.show_answer_in_email}"
      }.join("\n\n")
    end
  end

  def show_answer_in_csv(is_s3_submission)
    if questions.present?
      header_values_hash = {}
      questions.each.with_index(1) do |question, index|
        question.show_answer_in_csv(is_s3_submission:).each do |header, value|
          header_values_hash[I18n.t("submission_csv.repeatable_answer_header", header:, index:)] = value
        end
      end
      header_values_hash
    end
  end

  def remove_answer(answer_index)
    questions.delete_at(answer_index - 1)
    if questions.empty?
      add_blank_answer
    end
  end

  def min_answers?
    min_answers = @question.is_optional? ? 0 : 1

    questions.length <= min_answers
  end

private

  def add_blank_answer
    questions << @question.dup

    questions[answer_index - 1]
  end
end
