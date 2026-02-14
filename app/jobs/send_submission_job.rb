class SendSubmissionJob < SubmissionDeliveryJob
  # this translates to approximately 4.5 hours of retrying in total
  TOTAL_ATTEMPTS = 10

  retry_on Aws::SESV2::Errors::ServiceError, wait: :polynomially_longer, attempts: TOTAL_ATTEMPTS

  def perform(submission)
    set_submission_logging_attributes(submission)

    new_delivery_attempt!(submission)

    message_id = AwsSesSubmissionService.new(submission:).submit

    update_delivery_reference!(submission, delivery_reference: message_id)
    record_submission_sent!
  rescue StandardError
    CloudWatchService.record_job_failure_metric(self.class.name)
    raise
  end
end
