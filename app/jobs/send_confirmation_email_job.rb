class SendConfirmationEmailJob < ApplicationJob
  queue_as :confirmation_emails
  MailerOptions = Data.define(:title, :is_preview, :timestamp, :submission_reference, :payment_url)

  def perform(submission:, notify_response_id:, confirmation_email_address:)
    set_submission_logging_attributes(submission)

    I18n.with_locale(submission.submission_locale || I18n.default_locale) do
      form = submission.form
      mail = FormSubmissionConfirmationMailer.send_confirmation_email(
        what_happens_next_markdown: form.what_happens_next_markdown,
        support_contact_details: form.support_details,
        notify_response_id:,
        confirmation_email_address:,
        mailer_options: mailer_options_for(submission:, form:),
      )

      mail.deliver_now
    end
  rescue StandardError
    CloudWatchService.record_job_failure_metric(self.class.name)
    raise
  end

private

  def mailer_options_for(submission:, form:)
    MailerOptions.new(
      title: form.name,
      is_preview: submission.preview?,
      timestamp: submission.submission_time,
      submission_reference: submission.reference,
      payment_url: submission.payment_url,
    )
  end
end
