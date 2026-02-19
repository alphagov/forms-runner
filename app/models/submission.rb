class Submission < ApplicationRecord
  has_many :submission_deliveries, dependent: :destroy
  has_many :deliveries, through: :submission_deliveries

  scope :for_daily_batch, lambda { |form_id, date, mode|
    start_time = date.in_time_zone(TimeZoneUtils.submission_time_zone).beginning_of_day
    end_time = start_time.end_of_day

    where(form_id:, created_at: start_time..end_time, mode: mode)
  }

  scope :ordered_by_form_version_and_date, lambda {
    order(Arel.sql("(form_document->>'updated_at')::timestamptz ASC, created_at ASC"))
  }

  delegate :preview?, to: :mode_object

  encrypts :answers

  def journey
    @journey ||= Flow::Journey.new(answer_store:, form:)
  end

  def form
    @form ||= form_from_document
  end

  def submission_time
    created_at.in_time_zone(TimeZoneUtils.submission_time_zone)
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
end
