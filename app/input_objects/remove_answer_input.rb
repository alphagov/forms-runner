class RemoveAnswerInput
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :remove_answer

  RADIO_OPTIONS = { yes: "yes", no: "no" }.freeze

  validates :remove_answer, presence: true, inclusion: { in: RADIO_OPTIONS.values }

  def remove_answer?
    remove_answer == RADIO_OPTIONS[:yes]
  end

  def values
    RADIO_OPTIONS.keys
  end
end
