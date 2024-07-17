class RoutingCondition
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :answer_value
  attribute :check_page_id
  attribute :created_at
  attribute :goto_page_id
  attribute :has_routing_errors
  attribute :id
  attribute :routing_page_id
  attribute :skip_to_end
  attribute :updated_at
  attribute :validation_errors

  def from_json(json)
    attributes = HashWithIndifferentAccess.new(json)

    extracted_attributes = {
      validation_errors: Array(attributes["validation_errors"]).map do |ve|
        ValidationError.new(ve)
      end
    }
  end
end
