class Api::V2::FormDocumentRepository
  class << self
    def find(form_id:, tag:, language: :en)
      raise ActiveResource::ResourceNotFound.new(404, "Not Found") unless form_id.to_s =~ /^[[:alnum:]]+$/

      form_document = if language == :en
                        Api::V2::FormDocumentResource.get(form_id, tag)
                      else
                        Api::V2::FormDocumentResource.get(form_id, tag, language)
                      end

      form = Form.new(form_document, true)
      form.document_json = form_document
      form.prefix_options = { form_id:, tag:, language: }
      form
    end

    def find_with_mode(form_id:, mode:, language: :en)
      if language == :en
        Api::V2::FormDocumentRepository.find(form_id:, tag: mode.tag)
      else
        Api::V2::FormDocumentRepository.find(form_id:, tag: mode.tag, language:)
      end
    end
  end
end
