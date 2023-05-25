class Page < ActiveResource::Base
  self.site = Settings.forms_api.base_url
  self.prefix = "/api/v1/forms/:form_id/"
  self.include_format_in_path = false
  headers["X-API-Token"] = Settings.forms_api.auth_key

  belongs_to :form

  def form_id
    @prefix_options[:form_id]
  end

  def has_next_page?
    @attributes.include?("next_page") && !@attributes["next_page"].nil?
  end

  # TODO: - Remove this method and use the page.position instead
  def number(form)
    index = form.pages.index(self)
    index + 1
  end

  def answer_settings
    @attributes["answer_settings"] || {}
  end
end
