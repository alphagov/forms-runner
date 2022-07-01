class Form < ActiveResource::Base
  self.site = ENV.fetch("API_BASE").to_s
  self.prefix = "/api/v1/"
  self.include_format_in_path = false

  has_many :pages

  def last_page
    pages.find { |p| !p.has_next? }
  end
end
