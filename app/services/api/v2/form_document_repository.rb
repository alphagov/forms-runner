class Api::V2::FormDocumentRepository
  class << self
    def find(form_id:, tag:, language: :en)
      raise ActiveResource::ResourceNotFound.new(404, "Not Found") unless form_id.to_s =~ /^[[:alnum:]]+$/

      form_document = Api::V2::FormDocumentResource.get(form_id, tag, **options_for_language(language))
      form = Form.new(form_document, true)
      form.document_json = form_document
      form.prefix_options = { form_id:, tag: }
      form
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
