class Page < ActiveResource::Base
  PAGE_ID_REGEX = /\d+/

  self.site = Settings.forms_api.base_url
  self.prefix = "/api/v1/forms/:form_id/"
  self.include_format_in_path = false
  headers["X-API-Token"] = Settings.forms_api.auth_key

  belongs_to :form

  def self.deprecator
    Rails.application.deprecators[:forms_api]
  end

  def self.find(...)
    deprecator.warn "the /forms/:id/pages endpoints are deprecated and will be removed in API v2"
    super
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
