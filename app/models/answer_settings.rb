class AddressInputType
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serializers::JSON

  attribute :international_address
  attribute :uk_address

  def self.from_json(json)
    attributes = HashWithIndifferentAccess.new(json)

    extracted_attributes = {
      international_address: attributes[:international_address],
      uk_address: attributes[:uk_address],
    }

    new(extracted_attributes)
  end
end

class AnswerSettings
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serializers::JSON

  attribute :selection_options, default: []
  attribute :only_one_option
  attribute :input_type
  attribute :title_needed

  def self.from_json(json, answer_type)
    attributes = HashWithIndifferentAccess.new(json)

    extracted_attributes = {
      selection_options: Array(attributes[:selection_options]).map do |so|
        SelectionOption.new(so)
      end,
      only_one_option: attributes[:only_one_option],
      input_type: answer_type == "address" ? AddressInputType.from_json(attributes[:input_type]) : attributes[:input_type],
      title_needed: attributes[:title_needed],
    }

    new(extracted_attributes)
  end
end
