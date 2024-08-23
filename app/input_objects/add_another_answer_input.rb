class AddAnotherAnswerInput
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :add_another_answer, :max_answers

  RADIO_OPTIONS = { yes: "yes", no: "no" }.freeze

  validates :add_another_answer, presence: true, inclusion: { in: RADIO_OPTIONS.values }
  validate :max_answers_reached, if: :add_another_answer?

  def add_another_answer?
    add_another_answer == RADIO_OPTIONS[:yes]
  end

  def values
    RADIO_OPTIONS.keys
  end

private

  def max_answers_reached
    errors.add :add_another_answer, :max_answers_reached if max_answers
  end
end
