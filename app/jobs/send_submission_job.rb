class SendSubmissionJob < ApplicationJob
  queue_as :submissions

  # this translates to approximately 4.5 hours of retrying in total
  TOTAL_ATTEMPTS = 10

  retry_on Aws::SESV2::Errors::ServiceError, wait: :polynomially_longer, attempts: TOTAL_ATTEMPTS

  def perform(submission)
    set_submission_logging_attributes(submission)

    message_id = AwsSesSubmissionService.new(submission:).submit

    existing_delivery = submission.single_submission_delivery
    if existing_delivery.present?
      existing_delivery.update!(
        delivery_reference: message_id,
        last_attempt_at: Time.zone.now,
        delivered_at: nil,
        failed_at: nil,
        failure_reason: nil,
      )
    else
      submission.deliveries.create!(
        delivery_reference: message_id,
        last_attempt_at: Time.zone.now,
      )
    end

    milliseconds_since_scheduled = (Time.current - scheduled_at_or_enqueued_at).in_milliseconds.round
    EventLogger.log_form_event("submission_email_sent", { milliseconds_since_scheduled: })
    CloudWatchService.record_submission_sent_metric(milliseconds_since_scheduled)
  rescue StandardError
    CloudWatchService.record_job_failure_metric(self.class.name)
    raise
  end

private

  def scheduled_at_or_enqueued_at
    scheduled_at || enqueued_at
  end
end
