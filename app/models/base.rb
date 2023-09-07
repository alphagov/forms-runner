class Base < ActiveResource::Base
  self.site = Settings.forms_api.base_url
  self.include_format_in_path = false

  def self.headers
    headers = super
    headers["X-API-Token"] = Settings.forms_api.auth_key
    headers
  end
end
