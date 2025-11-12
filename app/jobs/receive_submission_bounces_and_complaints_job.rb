class ReceiveSubmissionBouncesAndComplaintsJob < ApplicationJob
  queue_as :background

  SQS_QUEUE_NAME = "submission_email_ses_bounces_and_complaints_queue".freeze

  def perform
    CloudWatchService.record_job_started_metric(self.class.name)
    CurrentJobLoggingAttributes.job_class = self.class.name
    CurrentJobLoggingAttributes.job_id = job_id

    poller = AwsSesMessagePoller.new(
      queue_name: SQS_QUEUE_NAME,
      job_class_name: self.class.name,
      job_id: job_id,
    )

    poller.poll do |submission, ses_message|
      ses_event_type = ses_message["eventType"]

      raise "Unexpected event type:#{ses_event_type}" unless %w[Bounce Complaint].include?(ses_event_type)

      process_bounce(submission, ses_message) if ses_event_type == "Bounce"
      process_complaint(submission) if ses_event_type == "Complaint"
    end
  end

private

  def process_bounce(submission, ses_message)
    set_submission_logging_attributes(submission)

    # Don't mark preview submissions as bounced, just log that they bounced. We don't need to attempt to resend preview
    # submissions so these can be deleted as normal by the deletion job.
    submission.bounced! unless submission.preview?

    bounce_object = ses_message["bounce"] || {}

    ses_bounce = {
      bounce_type: bounce_object["bounceType"],
      bounce_sub_type: bounce_object["bounceSubType"],
      reporting_mta: bounce_object["reportingMTA"],
      timestamp: bounce_object["timestamp"],
      feedback_id: bounce_object["feedbackId"],
    }

    bounced_recipients = bounce_object["bouncedRecipients"]&.map do |recipient|
      {
        email_address: recipient["emailAddress"],
        action: recipient["action"],
        status: recipient["status"],
        diagnostic_code: recipient["diagnosticCode"],
      }
    end

    EventLogger.log_form_event("submission_bounced", ses_bounce: ses_bounce.merge(bounced_recipients:))

    unless submission.preview?
      Sentry.capture_message("Submission email bounced for form #{submission.form_id} - #{self.class.name}:",
                             fingerprint: ["{{ default }}", submission.form_id],
                             extra: {
                               form_id: submission.form_id,
                               submission_reference: submission.reference,
                               job_id:,
                               ses_bounce:,
                             })
    end
  end

  def process_complaint(submission)
    set_submission_logging_attributes(submission)

    EventLogger.log_form_event("submission_complaint")
  end
end
