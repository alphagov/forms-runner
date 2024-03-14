class FormSubmissionConfirmationMailer < GovukNotifyRails::Mailer
  def send_confirmation_email(what_happens_next_markdown:, support_contact_details:, notify_response_id:, confirmation_email_address:, mailer_options:)
    set_template(Settings.govuk_notify.form_filler_confirmation_email_template_id)

    set_personalisation(
      title: mailer_options.title,
      what_happens_next_text: what_happens_next_markdown,
      support_contact_details:,
      submission_time: mailer_options.timestamp.strftime("%l:%M%P").strip,
      submission_date: mailer_options.timestamp.strftime("%-d %B %Y"),
      # GOV.UK Notify's templates have conditionals, but only positive
      # conditionals, so to simulate negative conditionals we add two boolean
      # flags; but they must always have opposite values!
      test: make_notify_boolean(mailer_options.preview_mode),
      include_submission_reference: make_notify_boolean(FeatureService.enabled?(:reference_numbers_enabled)),
      submission_reference: FeatureService.enabled?(:reference_numbers_enabled) ? mailer_options.submission_reference : "",
      include_payment_link: make_notify_boolean(mailer_options.payment_url.present?),
      payment_link: mailer_options.payment_url || "",
    )

    set_reference(notify_response_id)

    set_email_reply_to(Settings.govuk_notify.form_submission_email_reply_to_id)

    mail(to: confirmation_email_address)
  end

private

  def make_notify_boolean(bool)
    bool ? "yes" : "no"
  end
end
