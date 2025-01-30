class RemoveFileInput
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :remove_file

  RADIO_OPTIONS = { yes: "yes", no: "no" }.freeze

  validates :remove_file, presence: true, inclusion: { in: RADIO_OPTIONS.values }

  def remove_file?
    remove_file == RADIO_OPTIONS[:yes]
  end

  def values
    RADIO_OPTIONS.keys
  end
end
