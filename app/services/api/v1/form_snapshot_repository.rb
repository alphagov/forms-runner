class Api::V1::FormSnapshotRepository
  class << self
    def find_with_mode(id:, mode:)
      if FeatureService.enabled? :api_v2
        v2_find_with_mode(id:, mode:)
      else
        Form.find_with_mode(id:, mode:)
      end
    end

  private

    def converter
      @converter ||= Api::V1::Converter.new
    end

    def v2_find_with_mode(id:, mode:)
      raise ActiveResource::ResourceNotFound.new(404, "Not Found") unless id.to_s =~ /^[[:alnum:]]+$/

      tag = if mode.preview_draft?
              :draft
            elsif mode.preview_archived?
              :archived
            elsif mode.live?
              :live
            elsif mode.preview_live?
              :live
            end

      v2_form_document = Api::V2::FormDocumentResource.find(id, tag)
      v2_blob = v2_form_document.as_json

      v1_blob = converter.to_api_v1_form_snapshot(v2_blob)
      Form.new(v1_blob, true)
    end
  end
end
