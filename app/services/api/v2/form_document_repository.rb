class Api::V2::FormDocumentRepository
  class << self
    def find(form_id:, tag:)
      raise ActiveResource::ResourceNotFound.new(404, "Not Found") unless form_id.to_s =~ /^[[:alnum:]]+$/

      form_document = Api::V2::FormDocumentResource.get(form_id, tag)
      form = Form.new(form_document, true)
      form.document_json = form_document
      form.prefix_options = { form_id:, tag: }
      form
    end

    def find_with_mode(form_id:, mode:)
      find(form_id:, tag: mode.tag)
    end
  end
end
