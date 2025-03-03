class Submission < ApplicationRecord
  delegate :preview?, to: :mode_object

  def journey
    @journey ||= Flow::Journey.new(answer_store:, form:)
  end

  def form
    @form ||= Api::V1::FormSnapshotRepository.find_with_mode(id: form_id, mode: mode_object)
  end

private

  def mode_object
    Mode.new(mode)
  end

  def answer_store
    Store::DatabaseAnswerStore.new(answers)
  end
end
