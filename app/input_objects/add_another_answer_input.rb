class AddAnotherAnswerInput
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :add_another_answer

  RADIO_OPTIONS = { yes: "yes", no: "no" }.freeze

  validates :add_another_answer, presence: true, inclusion: { in: RADIO_OPTIONS.values }

  def add_another_answer?
    add_another_answer == RADIO_OPTIONS[:yes]
  end

  def values
    RADIO_OPTIONS.keys
  end
end
