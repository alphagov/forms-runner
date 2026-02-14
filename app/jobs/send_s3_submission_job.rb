class SendS3SubmissionJob < SubmissionDeliveryJob
  def perform(submission)
    set_submission_logging_attributes(submission)

    new_delivery_attempt!(submission)

    key = S3SubmissionService.new(submission:).submit

    update_delivery_reference!(submission, delivery_reference: key)
    record_submission_sent!
  rescue StandardError
    CloudWatchService.record_job_failure_metric(self.class.name)
    raise
  end
end
