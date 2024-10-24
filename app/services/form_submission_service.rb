class FormSubmissionService
  class << self
    def call(**args)
      new(**args)
    end
  end

  MailerOptions = Data.define(:title, :preview_mode, :timestamp, :submission_reference, :payment_url)

  def initialize(current_context:, email_confirmation_input:, preview_mode:)
    @current_context = current_context
    @form = current_context.form
    @email_confirmation_input = email_confirmation_input
    @requested_email_confirmation = @email_confirmation_input.send_confirmation == "send_email"
    @preview_mode = preview_mode
    @timestamp = submission_timestamp
    @submission_reference = ReferenceNumberService.generate

    CurrentLoggingAttributes.submission_reference = @submission_reference
  end

  def submit
    submit_form_to_processing_team
    submit_confirmation_email_to_user if @requested_email_confirmation

    @submission_reference
  end

private

  def submit_form_to_processing_team
    raise StandardError, "Form id(#{@form.id}) has no completed steps i.e questions/answers to submit" if @current_context.completed_steps.blank?

    if @form.submission_type == "s3"
      s3_submission_service.submit
    else
      notify_submission_service.submit
    end

    LogEventService.log_submit(@current_context,
                               requested_email_confirmation: @requested_email_confirmation,
                               preview: @preview_mode,
                               submission_type: @form.submission_type)
  end

  def submit_confirmation_email_to_user
    unless @form.what_happens_next_markdown.present? && has_support_contact_details?
      Rails.logger.info "Skipping sending confirmation email to user as what happens next and support contact details have not been set"
      return nil
    end

    mail = FormSubmissionConfirmationMailer.send_confirmation_email(
      what_happens_next_markdown: @form.what_happens_next_markdown,
      support_contact_details: formatted_support_details,
      notify_response_id: @email_confirmation_input.confirmation_email_reference,
      confirmation_email_address: @email_confirmation_input.confirmation_email_address,
      mailer_options:,
    ).deliver_now

    CurrentLoggingAttributes.confirmation_email_id = mail.govuk_notify_response.id
  end

  def notify_submission_service
    NotifySubmissionService.new(
      current_context: @current_context,
      notify_email_reference: @email_confirmation_input.submission_email_reference,
      mailer_options:,
    )
  end

  def s3_submission_service
    S3SubmissionService.new(
      current_context: @current_context,
      timestamp: @timestamp,
      submission_reference: @submission_reference,
    )
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

    notify_body = NotifyTemplateFormatter.new
    formatted_phone_number = notify_body.normalize_whitespace(@form.support_phone)

    "#{formatted_phone_number}\n\n[#{I18n.t('support_details.call_charges')}](#{@current_context.support_details.call_back_url})"
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
                      preview_mode: @preview_mode,
                      timestamp: @timestamp,
                      submission_reference: @submission_reference,
                      payment_url: @form.payment_url_with_reference(@submission_reference))
  end
end
