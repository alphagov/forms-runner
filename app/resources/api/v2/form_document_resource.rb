class Api::V2::FormDocumentResource < ActiveResource::Base
  self.element_name = "form"
  self.site = Settings.forms_api.base_url
  self.prefix = "/api/v2/"
  self.include_format_in_path = false

  class Step < ActiveResource::Base
    self.site = Settings.forms_api.base_url
    self.prefix = "/api/v2/"
  end

  class << self
    def find(form_id, tag, params: {})
      super(:one, from: "#{prefix}#{collection_name}/#{form_id}/#{tag}", params:)
    end

    def get(form_id, tag, **options)
      super("#{form_id}/#{tag}", **options)
    end
  end
end
