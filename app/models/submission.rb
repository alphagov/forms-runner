class Submission < ApplicationRecord
  delegate :preview?, to: :mode_object

  def journey
    @journey ||= Flow::Journey.new(answer_store:, form:)
  end

  def form
    @form ||= get_form
  end

private

  def mode_object
    Mode.new(mode)
  end

  def answer_store
    Store::DatabaseAnswerStore.new(answers)
  end

  def get_form
    return form_from_document if form_document.present?

    # We can remove this fallback when all submissions that don't have the form_document stored have been deleted
    Api::V1::FormSnapshotRepository.find_with_mode(id: form_id, mode: mode_object)
  end

  def form_from_document
    v1_blob = Api::V1::Converter.new.to_api_v1_form_snapshot(form_document)
    Form.new(v1_blob, true)
  end
end
