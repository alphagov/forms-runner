class ReceiveSubmissionBouncesAndComplaintsJob < ApplicationJob
  include ReceiveSubmissionJobHelper

  queue_as :background

  SQS_QUEUE_NAME = "submission_email_ses_bounces_and_complaints_queue".freeze

private

  def process_ses_event(ses_event_type, submission)
    raise "Unexpected event type:#{ses_event_type}" unless %w[Bounce Complaint].include?(ses_event_type)

    process_bounce(submission) if ses_event_type == "Bounce"
    process_complaint(submission) if ses_event_type == "Complaint"
  end

  def process_bounce(submission)
    set_submission_logging_attributes(submission)

    submission.bounced!

    EventLogger.log_form_event("submission_bounced")

    Sentry.capture_message("Submission email bounced - #{self.class.name}:", extra: {
      form_id: submission.form_id,
      submission_reference: submission.reference,
      job_id:,
    })
  end

  def process_complaint(submission)
    set_submission_logging_attributes(submission)

    EventLogger.log_form_event("submission_complaint")
  end
end
