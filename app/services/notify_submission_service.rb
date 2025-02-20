class NotifySubmissionService
  def initialize(journey:, form:, notify_email_reference:, mailer_options:)
    @journey = journey
    @form = form
    @notify_email_reference = notify_email_reference
    @mailer_options = mailer_options
  end

  def submit
    if !@mailer_options.is_preview && @form.submission_email.blank?
      raise StandardError, "Form id(#{@form.id}) is missing a submission email address"
    end

    if @form.submission_email.blank? && @mailer_options.is_preview
      Rails.logger.info "Skipping sending submission email for preview submission, as the submission email address has not been set"
      return
    end

    if @form.submission_type == "email_with_csv"
      deliver_submission_email_with_csv_attachment_with_fallback
    else
      deliver_submission_email
    end
  end

private

  def deliver_submission_email_with_csv_attachment
    Tempfile.create do |file|
      write_submission_csv(file)
      deliver_submission_email(file)
    end
  end

  def deliver_submission_email(csv_file = nil)
    mail = FormSubmissionMailer
      .email_confirmation_input(text_input: email_body,
                                notify_response_id: @notify_email_reference,
                                submission_email: @form.submission_email,
                                mailer_options: @mailer_options,
                                csv_file:).deliver_now

    CurrentLoggingAttributes.submission_email_id = mail.govuk_notify_response.id
  end

  def deliver_submission_email_with_csv_attachment_with_fallback
    deliver_submission_email_with_csv_attachment
  rescue Notifications::Client::BadRequestError => e
    Sentry.capture_exception(e)
    Rails.logger.error("Error when attempting to send submission email with CSV attachment, retrying without attachment", {
      rescued_exception: [e.class.name, e.message],
    })
    deliver_submission_email
  end

  def write_submission_csv(file)
    CsvGenerator.write_submission(
      all_steps: @journey.all_steps,
      submission_reference: @mailer_options.submission_reference,
      timestamp: @mailer_options.timestamp,
      output_file_path: file.path,
    )
  end

  def email_body
    NotifyTemplateFormatter.new.build_question_answers_section(@journey.completed_steps)
  end
end
