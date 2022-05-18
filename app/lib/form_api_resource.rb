class FormApiResource < ActiveResource::Base
  self.site = "#{ENV.fetch('API_BASE')}/v1"
  self.include_format_in_path = false
  self.element_name = "form"
end
