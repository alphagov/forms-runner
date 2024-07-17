class Page
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serializers::JSON

  PAGE_ID_REGEX = /\d+/

  attribute :id
  attribute :question_text
  attribute :hint_text
  attribute :answer_type
  attribute :next_page
  attribute :is_optional
  attribute :answer_settings
  attribute :created_at
  attribute :updated_at
  attribute :form_id
  attribute :position
  attribute :page_heading
  attribute :guidance_markdown
  attribute :routing_conditions, default: []

  def has_next_page?
    next_page.present?
  end

  def self.from_json(json)
    attributes = HashWithIndifferentAccess.new(json)

    extracted_attributes = {
      id: attributes[:id],
      question_text: attributes[:question_text],
      hint_text: attributes[:hint_text],
      answer_type: attributes[:answer_type],
      next_page: attributes[:next_page],
      is_optional: attributes[:is_optional],
      created_at: attributes[:created_at],
      updated_at: attributes[:updated_at],
      form_id: attributes[:form_id],
      position: attributes[:position],
      page_heading: attributes[:page_heading],
      guidance_markdown: attributes[:guidance_markdown]
    }

    if attributes[:answer_settings].present?
      extracted_attributes[:answer_settings] = AnswerSettings.from_json(attributes[:answer_settings], attributes[:answer_type])
    end

    if attributes[:routing_conditions].present?
      extracted_attributes[:routing_conditions] = attributes[:routing_conditions].map do |rc|
        RoutingCondition.from_json(rc)
      end
    end

    new(extracted_attributes)
  end
end
