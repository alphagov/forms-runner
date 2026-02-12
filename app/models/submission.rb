class Submission < ApplicationRecord
  has_many :submission_deliveries, dependent: :destroy
  has_many :deliveries, through: :submission_deliveries

  scope :for_daily_batch, lambda { |form_id, date, mode|
    start_time = date.in_time_zone(TimeZoneUtils.submission_time_zone).beginning_of_day
    end_time = start_time.end_of_day

    where(form_id:, created_at: start_time..end_time, mode: mode).order(created_at: :desc)
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

  def self.group_by_form_version(submissions)
    submission_by_version = {}
    last_version = nil

    # For forms that have the same updated_at timestamp, we know they will be identical. If two forms have different
    # updated_at timestamps, we check to see if their steps are the same. If they are, we group those forms' submissions
    # together.
    submissions.group_by { |submission| submission.form.updated_at }.sort.to_h.each do |updated_at, submissions|
      if last_version && last_version.steps == submissions.first.form.steps
        submission_by_version[last_version.updated_at].push(*submissions)
      else
        submission_by_version[updated_at] = submissions
        last_version = submissions.first.form
      end
    end

    submission_by_version
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
