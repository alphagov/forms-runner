class SendSubmissionJob < ApplicationJob
  queue_as :submissions

  # this translates to approximately 4.5 hours of retrying in total
  TOTAL_ATTEMPTS = 10

  retry_on Aws::SESV2::Errors::ServiceError, wait: :polynomially_longer, attempts: TOTAL_ATTEMPTS

  def perform(submission)
    set_submission_logging_attributes(submission)

    message_id = AwsSesSubmissionService.new(submission:).submit
    sent_at = Time.zone.now

    submission.update!(
      mail_message_id: message_id,
      delivery_status: :pending,
      last_delivery_attempt: sent_at,
    )

    milliseconds_since_scheduled = (sent_at - scheduled_at_or_enqueued_at).in_milliseconds.round
    LogEventService.log_submission_sent(submission, milliseconds_since_scheduled:)
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
