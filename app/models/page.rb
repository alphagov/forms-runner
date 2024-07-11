class Page
  include ActiveModel::Model
  include ActiveModel::Attributes

  PAGE_ID_REGEX = /\d+/

  def initialize(attributes = {}, persisted = true)
    attributes["answer_settings"] = AnswerSettings.new(attributes["answer_settings"]) if attributes["answer_settings"].present?

    attributes["routing_conditions"] ||= []
    attributes["routing_conditions"] = attributes["routing_conditions"]&.map do |rc|
      RoutingCondition.new(rc)
    end

    super(attributes)
  end

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

  def as_json(*args)
    super.as_json["attributes"]
  end
end
