class FormSubmissionService
  class << self
    def submit(**args)
      new(**args).submit
    end
  end

  def initialize(submission:)
    @submission = submission
  end

  def submit
    set_logging_context

    deliver_submission
    send_confirmation_email if @submission.confirmation_email.present?

    @submission.reference
  end

private

  def set_logging_context
    CurrentRequestLoggingAttributes.submission_reference = @submission.reference
  end

  def deliver_submission
    if @submission.delivery_method == "s3"
      S3SubmissionJob.perform_later(@submission)
    else
      SendSubmissionJob.perform_later(@submission)
    end

    LogEventService.log_submit(
      @submission.form_id,
      requested_email_confirmation: @submission.confirmation_email.present?,
      preview: @submission.preview?,
      submission_type: @submission.delivery_method,
    )
  end

  def send_confirmation_email
    SendConfirmationEmailJob.perform_later(@submission)
  end
end
