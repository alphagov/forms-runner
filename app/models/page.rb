class Page < ActiveResource::Base
  self.site = ENV.fetch("API_BASE").to_s
  self.prefix = "/api/v1/forms/:form_id/"
  self.include_format_in_path = false
  self.headers["X-Api-Token"] = ENV["API_KEY"]

  belongs_to :form

  def form_id
    @prefix_options[:form_id]
  end

  def has_next?
    @attributes.include?("next") && !@attributes["next"].nil?
  end
end
