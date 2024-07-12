# needed to convert pages using ActiveResource
class PageResource
  def self.new(attributes, _persisted)
    Page.from_json(attributes)
  end
end

class FormResource < ActiveResource::Base
  self.site = Settings.forms_api.base_url
  self.element_name = "form"
  self.prefix = "/api/v1/"
  self.include_format_in_path = false
  headers["X-API-Token"] = Settings.forms_api.auth_key

  include FormRepository

  has_many :pages, class_name: "PageResource"

  def self.find_with_mode(id:, mode:)
    Form.new(find(:one, from: "#{prefix}forms/#{id}/#{mode}").attributes)
  end
end
