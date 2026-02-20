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

    poller.poll do |delivery, ses_message|
      submission = delivery.submissions.first
      ses_event_type = ses_message["eventType"]

      raise "Unexpected event type:#{ses_event_type}" unless %w[Bounce Complaint].include?(ses_event_type)

      process_bounce(delivery, submission, ses_message) if ses_event_type == "Bounce"
      process_complaint(submission, delivery) if ses_event_type == "Complaint"
    end
  end

private

  def process_bounce(delivery, submission, ses_message)
    mode = Mode.new(submission.mode)

    set_submission_logging_attributes(submission) if delivery.immediate?
    set_submission_batch_logging_attributes(form: submission.form, mode:) if delivery.daily?

    bounce_object = ses_message["bounce"] || {}

    unless submission.preview?
      bounced_timestamp = Time.zone.parse(bounce_object["timestamp"])

      delivery.update!(
        failed_at: bounced_timestamp,
        failure_reason: "bounced",
      )
    end

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

    process_immediate_delivery_bounce(delivery, submission, ses_bounce, bounced_recipients) if delivery.immediate?
    process_daily_delivery_bounce(delivery, submission, ses_bounce, bounced_recipients) if delivery.daily?
  end

  def process_immediate_delivery_bounce(delivery, submission, ses_bounce, bounced_recipients)
    EventLogger.log_form_event("submission_bounced", ses_bounce: ses_bounce.merge(bounced_recipients:))

    unless submission.preview?
      Sentry.capture_message("Submission email bounced for form #{submission.form_id} - #{self.class.name}:",
                             fingerprint: ["{{ default }}", submission.form_id],
                             extra: {
                               form_id: submission.form_id,
                               submission_reference: submission.reference,
                               delivery_reference: delivery.delivery_reference,
                               job_id:,
                               ses_bounce:,
                             })
    end
  end

  def process_daily_delivery_bounce(delivery, submission, ses_bounce, bounced_recipients)
    EventLogger.log_form_event("daily_batch_email_bounced", ses_bounce: ses_bounce.merge(bounced_recipients:))

    unless submission.preview?
      Sentry.capture_message("Daily submission batch email bounced for form #{submission.form_id} - #{self.class.name}:",
                             fingerprint: ["{{ default }}", submission.form_id],
                             extra: {
                               form_id: submission.form_id,
                               delivery_reference: delivery.delivery_reference,
                               delivery_schedule: delivery.delivery_schedule,
                               batch_date: submission.submission_time.to_date,
                               job_id:,
                               ses_bounce:,
                             })
    end
  end

  def process_complaint(submission, delivery)
    if delivery.immediate?
      set_submission_logging_attributes(submission)

      EventLogger.log_form_event("submission_complaint")
    elsif delivery.daily?
      set_submission_batch_logging_attributes(form: submission.form, mode: Mode.new(submission.mode))

      EventLogger.log_form_event("daily_batch_email_complaint")
    end
  end
end
