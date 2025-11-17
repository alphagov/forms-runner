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
    def find(form_id, tag, language = :en)
      super(:one, from: document_path(form_id, tag, language))
    end

    def get(form_id, tag, language = :en)
      if language == :en
        super("#{form_id}/#{tag}")
      else
        super("#{form_id}/#{tag}?language=#{language}")
      end
    end

  private

    def document_path(form_id, tag, language = :en)
      if language == :en
        "#{prefix}forms/#{form_id}/#{tag}"
      else
        "#{prefix}forms/#{form_id}/#{tag}?language=#{language}"
      end
    end
  end
end
