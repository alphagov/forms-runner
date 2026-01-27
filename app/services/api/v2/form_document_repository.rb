class Api::V2::FormDocumentRepository
  class << self
    def find(form_id:, tag:, language: :en)
      raise ActiveResource::ResourceNotFound.new(404, "Not Found") unless form_id.to_s =~ /^[[:alnum:]]+$/

      TelemetryService.trace("api.forms_admin.fetch_form", attributes: {
        "api.endpoint" => "#{Settings.forms_api.base_url}/api/v2/form/#{form_id}/#{tag}",
        "api.method" => "GET",
        "form.id" => form_id.to_s,
        "form.tag" => tag.to_s,
        "form.language" => language.to_s,
      }) do |span|
        form_document = Api::V2::FormDocumentResource.get(form_id, tag, **options_for_language(language))

        span.set_attribute("api.response.status", 200)
        span.set_attribute("form.name", form_document.name) if form_document.respond_to?(:name)

        form = Form.new(form_document, true)
        form.document_json = form_document
        form.prefix_options = { form_id:, tag: }
        form
      end
    rescue ActiveResource::ResourceNotFound => e
      # Re-raise but let the span record the error
      raise
    end

    def find_with_mode(form_id:, mode:, language: :en)
      find(form_id:, tag: mode.tag, language:)
    end

  private

    # Don't include English in the options hash as it's the default
    def options_for_language(language)
      return {} if language.blank? || language.to_sym == :en

      { language: language.to_sym }
    end
  end
end
