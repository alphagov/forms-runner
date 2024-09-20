class Api::V2::FormDocumentResource < ActiveResource::Base
  self.element_name = "form"
  self.site = Settings.forms_api.base_url
  self.prefix = "/api/v2/"
  self.include_format_in_path = false
  headers["X-API-Token"] = Settings.forms_api.auth_key

  class Step < ActiveResource::Base
    self.site = Settings.forms_api.base_url
    self.prefix = "/api/v2/"
  end

  class << self
    def find(form_id, tag)
      super(:one, from: document_path(form_id, tag))
    end

  private

    def document_path(form_id, tag)
      "#{prefix}forms/#{form_id}/#{tag}"
    end
  end
end
