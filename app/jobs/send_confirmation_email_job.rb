class SendConfirmationEmailJob < ApplicationJob
  queue_as :submissions

  MailerOptions = Data.define(:title, :is_preview, :timestamp, :submission_reference, :payment_url)

  def perform(submission)
    # Skip sending if the confirmation email has already been sent
    return if submission.confirmation_email_sent_at.present? || submission.confirmation_email.blank?

    mailer_options = MailerOptions.new(
      title: submission.form.name,
      is_preview: submission.preview?,
      timestamp: submission.created_at,
      submission_reference: submission.reference,
      payment_url: submission.form.payment_url_with_reference(submission.reference),
    )

    mail = FormSubmissionConfirmationMailer.send_confirmation_email(
      what_happens_next_markdown: submission.form.what_happens_next_markdown,
      support_contact_details: submission.form.support_details,
      notify_response_id: "#{submission.reference}-confirmation-email",
      confirmation_email_address: submission.confirmation_email,
      mailer_options:,
    ).deliver_now

    submission.update!(confirmation_email_sent_at: Time.current)

    CurrentRequestLoggingAttributes.confirmation_email_id = mail.govuk_notify_response.id
  end
end
