class SendSubmissionJob < ApplicationJob
  queue_as :submissions

  # this translates to approximately 4.5 hours of retrying in total
  TOTAL_ATTEMPTS = 10

  retry_on Aws::SESV2::Errors::ServiceError, wait: :polynomially_longer, attempts: TOTAL_ATTEMPTS

  def perform(submission)
    set_submission_logging_attributes(submission)

    form = submission.form
    mailer_options = FormSubmissionService::MailerOptions.new(title: form.name,
                                                              is_preview: submission.preview?,
                                                              timestamp: submission.submission_time,
                                                              submission_reference: submission.reference,
                                                              payment_url: form.payment_url_with_reference(submission.reference))

    message_id = AwsSesSubmissionService.new(
      journey: submission.journey,
      form: form,
      mailer_options:,
    ).submit

    submission.update!(
      mail_message_id: message_id,
      mail_status: :pending,
      sent_at: Time.zone.now,
    )

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
