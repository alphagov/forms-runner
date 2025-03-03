class SendSubmissionJob < ApplicationJob
  queue_as :default

  TOTAL_ATTEMPTS = 10

  retry_on Exception, wait: :polynomially_longer, attempts: TOTAL_ATTEMPTS

  def perform(submission)
    form = submission.form
    mailer_options = FormSubmissionService::MailerOptions.new(title: form.name,
                                                              is_preview: submission.preview?,
                                                              timestamp: submission.created_at,
                                                              submission_reference: submission.reference,
                                                              payment_url: form.payment_url_with_reference(submission.reference))

    message_id = AwsSesSubmissionService.new(
      journey: submission.journey,
      form: form,
      mailer_options:,
    ).submit

    submission.update!(mail_message_id: message_id)
  end
end
