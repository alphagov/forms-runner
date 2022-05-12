class Form < ActiveResource::Base
  self.site = ENV.fetch('API_BASE')
  self.include_format_in_path = false
end
