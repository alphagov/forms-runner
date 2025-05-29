class Submission < ApplicationRecord
  delegate :preview?, to: :mode_object

  encrypts :answers

  enum :mail_status, {
    pending: "pending",
    bounced: "bounced",
  }

  def journey
    @journey ||= Flow::Journey.new(answer_store:, form:)
  end

  def form
    @form ||= form_from_document
  end

  def submission_time
    created_at.in_time_zone(submission_timezone)
  end

  def self.emailed?(reference)
    submission = Submission.find_by(reference: reference)
    submission.mail_message_id.present? if submission.present?
  end

private

  def mode_object
    Mode.new(mode)
  end

  def answer_store
    Store::DatabaseAnswerStore.new(answers)
  end

  def form_from_document
    v1_blob = Api::V1::Converter.new.to_api_v1_form_snapshot(form_document)
    Form.new(v1_blob, true)
  end

  def submission_timezone
    Rails.configuration.x.submission.time_zone || "UTC"
  end
end
