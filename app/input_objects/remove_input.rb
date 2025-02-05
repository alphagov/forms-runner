class RemoveInput
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :remove

  RADIO_OPTIONS = { yes: "yes", no: "no" }.freeze

  validates :remove, presence: true, inclusion: { in: RADIO_OPTIONS.values }

  def remove?
    remove == RADIO_OPTIONS[:yes]
  end

  def values
    RADIO_OPTIONS.keys
  end
end
