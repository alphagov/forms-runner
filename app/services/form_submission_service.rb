class FormSubmissionService
  class << self
    def submit(**args)
      new(**args).submit
    end
  end

  MailerOptions = Data.define(:title, :is_preview, :timestamp, :submission_reference, :payment_url)

  def initialize(current_context:, email_confirmation_input:, mode:)
    @submission = Submission.create!(
      reference: ReferenceNumberService.generate,
      form_id: current_context.form.id,
      answers: current_context.answers,
      mode: mode,
      form_document: current_context.form.document_json,
    )

    @email_confirmation_input = email_confirmation_input

    CurrentRequestLoggingAttributes.submission_reference = @submission.reference
  end

  def submit
    deliver_submission
    send_confirmation_email if requested_confirmation?

    @submission.reference
  end

private

  def deliver_submission
    case @submission.delivery_method
    when "s3"
      S3SubmissionService.new(submission: @submission).submit
    else
      SendSubmissionJob.perform_later(@submission) do |job|
        unless job.successfully_enqueued?
          submission.destroy!
          message_suffix = ": #{job.enqueue_error&.message}" if job.enqueue_error
          raise StandardError, "Failed to enqueue submission for reference #{@submission.reference}#{message_suffix}"
        end
      end
    end

    LogEventService.log_submit(
      @submission.form_id,
      requested_email_confirmation: requested_confirmation?,
      preview: @submission.preview?,
      submission_type: @submission.delivery_method,
    )
  end

  def send_confirmation_email
    mail = FormSubmissionConfirmationMailer.send_confirmation_email(
      what_happens_next_markdown: @submission.form.what_happens_next_markdown,
      support_contact_details: @submission.form.support_details,
      notify_response_id: @email_confirmation_input.confirmation_email_reference,
      confirmation_email_address: @email_confirmation_input.confirmation_email_address,
      mailer_options:,
    ).deliver_now

    CurrentRequestLoggingAttributes.confirmation_email_id = mail.govuk_notify_response.id
  end

  def mailer_options
    MailerOptions.new(title: @submission.form.name,
                      is_preview: @submission.preview?,
                      timestamp: @submission.created_at,
                      submission_reference: @submission.reference,
                      payment_url: @submission.form.payment_url_with_reference(@submission.reference))
  end

  def requested_confirmation?
    @email_confirmation_input.send_confirmation == "send_email"
  end
end
