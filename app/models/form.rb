class Form < ActiveResource::Base
  self.site = ENV.fetch("API_BASE").to_s
  self.prefix = "/api/v1/"
  self.include_format_in_path = false

  has_many :pages

  def last_page
    pages.find { |p| !p.has_next? }
  end

  def page_by_id(page_id)
    pages.find { |p| p.id == page_id.to_i }
  end
end
