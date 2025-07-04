class FormSubmissionService
  class << self
    def call(**args)
      new(**args)
    end
  end

  MailerOptions = Data.define(:title, :is_preview, :timestamp, :submission_reference, :payment_url)

  def initialize(current_context:, email_confirmation_input:, mode:)
    @current_context = current_context
    @form = current_context.form
    @email_confirmation_input = email_confirmation_input
    @mode = mode
    @timestamp = submission_timestamp
    @submission_reference = ReferenceNumberService.generate

    CurrentRequestLoggingAttributes.submission_reference = @submission_reference
  end

  def submit
    submit_form_to_processing_team
    submit_confirmation_email_to_user if requested_confirmation?

    @submission_reference
  end

private

  def submit_form_to_processing_team
    raise StandardError, "Form id(#{@form.id}) has no completed steps i.e questions/answers to submit" if @current_context.completed_steps.blank?

    submit_using_form_submission_type
    LogEventService.log_submit(@current_context,
                               requested_email_confirmation: requested_confirmation?,
                               preview: @mode.preview?,
                               submission_type: @form.submission_type)
  end

  def submit_using_form_submission_type
    return s3_submission_service.submit if @form.submission_type == "s3"

    submit_via_aws_ses
  end

  def submit_confirmation_email_to_user
    mail = FormSubmissionConfirmationMailer.send_confirmation_email(
      what_happens_next_markdown: @form.what_happens_next_markdown,
      support_contact_details: @form.support_details,
      notify_response_id: @email_confirmation_input.confirmation_email_reference,
      confirmation_email_address: @email_confirmation_input.confirmation_email_address,
      mailer_options:,
    ).deliver_now

    CurrentRequestLoggingAttributes.confirmation_email_id = mail.govuk_notify_response.id
  end

  def s3_submission_service
    S3SubmissionService.new(
      journey: @current_context.journey,
      form: @form,
      timestamp: @timestamp,
      submission_reference: @submission_reference,
      is_preview: @mode.preview?,
    )
  end

  def submit_via_aws_ses
    submission = Submission.create!(
      reference: @submission_reference,
      form_id: @form.id,
      answers: @current_context.answers,
      mode: @mode,
      form_document: @form.document_json,
    )

    SendSubmissionJob.perform_later(submission) do |job|
      unless job.successfully_enqueued?
        submission.destroy!
        message_suffix = ": #{job.enqueue_error&.message}" if job.enqueue_error
        raise StandardError, "Failed to enqueue submission for reference #{@submission_reference}#{message_suffix}"
      end
    end
  end

  def submission_timezone
    Rails.configuration.x.submission.time_zone || "UTC"
  end

  def submission_timestamp
    Time.use_zone(submission_timezone) { Time.zone.now }
  end

  def mailer_options
    MailerOptions.new(title: @form.name,
                      is_preview: @mode.preview?,
                      timestamp: @timestamp,
                      submission_reference: @submission_reference,
                      payment_url: @form.payment_url_with_reference(@submission_reference))
  end

  def requested_confirmation?
    @email_confirmation_input.send_confirmation == "send_email"
  end
end
