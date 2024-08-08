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

    @mailer_options = MailerOptions.new(title: form_title,
                                        preview_mode: @preview_mode,
                                        timestamp: @timestamp,
                                        submission_reference: @submission_reference,
                                        payment_url: @form.payment_url_with_reference(@submission_reference))

    CurrentLoggingAttributes.submission_reference = @submission_reference
  end

  def submit
    submit_form_to_processing_team
    submit_confirmation_email_to_user
    @submission_reference
  end

private

  def submit_form_to_processing_team
    raise StandardError, "Form id(#{@form.id}) has no completed steps i.e questions/answers to include in submission email" if @current_context.completed_steps.blank?

    if !@preview_mode && @form.submission_email.blank?
      raise StandardError, "Form id(#{@form.id}) is missing a submission email address"
    end

    csv_attached = false
    unless @form.submission_email.blank? && @preview_mode
      mail = if FeatureService.enabled?("csv_submission", @form)
               csv_attached = true
               deliver_submission_email_with_csv_attachment
             else
               deliver_submission_email
             end

      CurrentLoggingAttributes.submission_email_id = mail.govuk_notify_response.id
    end

    LogEventService.log_submit(@current_context, requested_email_confirmation: @requested_email_confirmation, preview: @preview_mode, csv_attached:)
  end

  def submit_confirmation_email_to_user
    return nil unless @form.what_happens_next_markdown.present? && has_support_contact_details?
    return nil unless @requested_email_confirmation

    mail = FormSubmissionConfirmationMailer.send_confirmation_email(
      what_happens_next_markdown: @form.what_happens_next_markdown,
      support_contact_details: formatted_support_details,
      notify_response_id: @email_confirmation_input.confirmation_email_reference,
      confirmation_email_address: @email_confirmation_input.confirmation_email_address,
      mailer_options: @mailer_options,
    ).deliver_now

    CurrentLoggingAttributes.confirmation_email_id = mail.govuk_notify_response.id
  end

  def deliver_submission_email(csv_file = nil)
    FormSubmissionMailer
      .email_confirmation_input(text_input: email_body,
                                notify_response_id: @email_confirmation_input.submission_email_reference,
                                submission_email: @form.submission_email,
                                mailer_options: @mailer_options,
                                csv_file:).deliver_now
  end

  def deliver_submission_email_with_csv_attachment
    Tempfile.create do |file|
      SubmissionCsvService.new(
        current_context: @current_context,
        submission_reference: @submission_reference,
        timestamp: @timestamp,
        output_file_path: file.path,
      ).write
      deliver_submission_email(file)
    end
  end

  def form_title
    @form.name
  end

  def email_body
    NotifyTemplateFormatter.new.build_question_answers_section(@current_context)
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
end
