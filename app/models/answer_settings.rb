class AddressInputType
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :international_address
  attribute :uk_address
end

class AnswerSettings
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :selection_options, default: []
  attribute :only_one_option
  attribute :input_type
  attribute :title_needed

  def initialize(attributes = {})
    attributes["selection_options"] ||= []
    attributes["selection_options"] = attributes["selection_options"].map do |so|
      SelectionOption.new(so)
    end

    attributes["input_type"] = AddressInputType.new(attributes["input_type"]) if attributes["answer_type"] == "address"
    super(attributes)
  end
end
