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
    @requested_email_confirmation = @email_confirmation_input.send_confirmation == "send_email"
    @mode = mode
    @timestamp = submission_timestamp
    @submission_reference = ReferenceNumberService.generate

    CurrentRequestLoggingAttributes.submission_reference = @submission_reference
  end

  def submit
    submit_form_to_processing_team
    submit_confirmation_email_to_user if @requested_email_confirmation

    @submission_reference
  end

private

  def submit_form_to_processing_team
    raise StandardError, "Form id(#{@form.id}) has no completed steps i.e questions/answers to submit" if @current_context.completed_steps.blank?

    submit_using_form_submission_type
    LogEventService.log_submit(@current_context,
                               requested_email_confirmation: @requested_email_confirmation,
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
      support_contact_details: formatted_support_details,
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

  def form_title
    @form.name
  end

  def submission_timezone
    Rails.configuration.x.submission.time_zone || "UTC"
  end

  def submission_timestamp
    Time.use_zone(submission_timezone) { Time.zone.now }
  end

  def has_support_contact_details?
    [@form.support_email, @form.support_phone].any?(&:present?) || [@form.support_url, @form.support_url_text].all?(&:present?)
  end

  def formatted_support_details
    return nil unless has_support_contact_details?

    [support_phone_details, support_email_details, support_online_details].compact_blank.join("\n\n")
  end

  def support_phone_details
    return nil if @form.support_phone.blank?

    formatted_phone_number = normalize_whitespace(@form.support_phone)

    "#{formatted_phone_number}\n\n[#{I18n.t('support_details.call_charges')}](#{@current_context.support_details.call_charges_url})"
  end

  def support_email_details
    return nil if @form.support_email.blank?

    "[#{@form.support_email}](mailto:#{@form.support_email})"
  end

  def support_online_details
    return nil if [@form.support_url, @form.support_url_text].all?(&:blank?)

    "[#{@form.support_url_text}](#{@form.support_url})"
  end

  def mailer_options
    MailerOptions.new(title: form_title,
                      is_preview: @mode.preview?,
                      timestamp: @timestamp,
                      submission_reference: @submission_reference,
                      payment_url: @form.payment_url_with_reference(@submission_reference))
  end

  def normalize_whitespace(text)
    text.strip.gsub(/\r\n?/, "\n").split(/\n\n+/).map(&:strip).join("\n\n")
  end
end
