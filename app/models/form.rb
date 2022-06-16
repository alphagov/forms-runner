class Form < ActiveResource::Base
  self.site = "#{ENV.fetch('API_BASE')}"
  self.prefix = "/api/v1/"
  self.include_format_in_path = false

  has_many :pages
end
