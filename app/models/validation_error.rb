class ValidationError
  include ActiveModel::Model
  include ActiveModel::Attributes
  # { name: "goto_page_doesnt_exist" }
  # { name: "answer_value_doesnt_exist" }
  # { name: "cannot_route_to_next_page" }
  # { name: "cannot_have_goto_page_before_routing_page" }
  attribute :name
end
