class Page < Base
  self.prefix = "/api/v1/forms/:form_id/"

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
end
