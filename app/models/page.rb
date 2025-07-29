class Page < ActiveResource::Base
  PAGE_ID_REGEX = /\d+/

  self.site = Settings.forms_api.base_url
  self.prefix = "/api/v2/forms/:form_id/"
  self.include_format_in_path = false

  belongs_to :form

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

  def question_text(locale)
    return @attributes["question_text_cy"] if locale == "cy" && @attributes["question_text_cy"]

    @attributes["question_text_en"] || @attributes["question_text"]
  end

  def page_heading(locale)
    return @attributes["page_heading_cy"] if locale == "cy" && @attributes["page_heading_cy"]

    @attributes["page_heading_en"] || @attributes["page_heading"] || false
  end

  def guidance_markdown(locale)
    return @attributes["guidance_markdown_cy"] if locale == "cy" && @attributes["guidance_markdown_cy"]

    @attributes["guidance_markdown_en"] || @attributes["guidance_markdown"] || false
  end
end
