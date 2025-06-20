class Api::V1::FormSnapshotRepository
  class << self
    def find_with_mode(id:, mode:)
      v2_find_with_mode(id:, mode:)
    end

    def find_archived(id:)
      find_with_tag(id, :archived)
    end

  private

    def converter
      @converter ||= Api::V1::Converter.new
    end

    def v2_find_with_mode(id:, mode:)
      tag = if mode.preview_draft?
              :draft
            elsif mode.preview_archived?
              :archived
            elsif mode.live?
              :live
            elsif mode.preview_live?
              :live
            end

      find_with_tag(id, tag)
    end

    def find_with_tag(id, tag)
      raise ActiveResource::ResourceNotFound.new(404, "Not Found") unless id.to_s =~ /^[[:alnum:]]+$/

      v2_form_document = Api::V2::FormDocumentResource.find(id, tag)
      v2_blob = v2_form_document.as_json

      v1_blob = converter.to_api_v1_form_snapshot(v2_blob)

      form = Form.new(v1_blob, true)
      form.document_json = v2_blob
      form
    end
  end
end
