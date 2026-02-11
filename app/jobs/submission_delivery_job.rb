class SubmissionDeliveryJob < ApplicationJob
  queue_as :submissions

private

  def new_delivery_attempt!(submission)
    submission.single_submission_delivery.update!(
      last_attempt_at: Time.zone.now,
      delivered_at: nil,
      failed_at: nil,
      failure_reason: nil,
    )
  end

  def update_delivery_reference!(submission, delivery_reference:)
    submission.single_submission_delivery.update!(
      delivery_reference: delivery_reference,
    )
  end

  def record_submission_sent!
    milliseconds_since_scheduled = (Time.current - scheduled_at_or_enqueued_at).in_milliseconds.round
    EventLogger.log_form_event("submission_email_sent", { milliseconds_since_scheduled: })
    CloudWatchService.record_submission_sent_metric(milliseconds_since_scheduled)
  end

  def scheduled_at_or_enqueued_at
    scheduled_at || enqueued_at
  end
end
