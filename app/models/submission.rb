class Submission < ApplicationRecord
  has_many :submission_deliveries, dependent: :destroy
  has_many :deliveries, through: :submission_deliveries

  delegate :preview?, to: :mode_object

  encrypts :answers

  def journey
    @journey ||= Flow::Journey.new(answer_store:, form:)
  end

  def form
    @form ||= form_from_document
  end

  def submission_time
    created_at.in_time_zone(submission_timezone)
  end

  def payment_url
    form.payment_url_with_reference(reference)
  end

  def single_submission_delivery
    deliveries.immediate.sole
  end

  def self.sent?(reference)
    submission = Submission.find_by(reference: reference)
    submission&.single_submission_delivery&.delivery_reference&.present?
  end

private

  def mode_object
    Mode.new(mode)
  end

  def answer_store
    Store::DatabaseAnswerStore.new(answers)
  end

  def form_from_document
    Form.new(form_document, true)
  end

  def submission_timezone
    Rails.configuration.x.submission.time_zone || "UTC"
  end
end
