class Page < ActiveResource::Base
  PAGE_ID_REGEX = /\d+/

  self.site = Settings.forms_api.base_url
  self.prefix = "/api/v2/forms/:form_id/"
  self.include_format_in_path = false

  belongs_to :form

  def self.from_attributes(attributes, persisted)
    # If anwer_settings doesn't have a value key, add one from the name
    if attributes["answer_settings"].present? && attributes["answer_settings"]["selection_options"].present?

      attributes["answer_settings"]["selection_options"].each do |so|
        if so["value"].blank?
          so.merge!(value: so["name"])
        end
      end
    end
    new(attributes, persisted)
  end

  def form_id
    @prefix_options[:form_id]
  end

  def has_next_page?
    @attributes.include?("next_page") && !@attributes["next_page"].nil?
  end

  def answer_settings
    @attributes["answer_settings"] || {}
  end

  def repeatable?
    @attributes["is_repeatable"] || false
  end
end
