class FormSubmissionConfirmationMailer < GovukNotifyRails::Mailer
  def send_confirmation_email(what_happens_next_markdown:, support_contact_details:, notify_response_id:, confirmation_email_address:, mailer_options:)
    set_template(template_id)

    set_personalisation(
      title: mailer_options.title,
      what_happens_next_text: what_happens_next_markdown.presence || default_what_happens_next_text,
      support_contact_details: support_contact_details.presence || default_support_contact_details_text,
      submission_time: mailer_options.timestamp.strftime("%l:%M%P").strip,
      submission_date: I18n.l(mailer_options.timestamp, format: "%-d %B %Y"),
      # GOV.UK Notify's templates have conditionals, but only positive
      # conditionals, so to simulate negative conditionals we add two boolean
      # flags; but they must always have opposite values!
      test: make_notify_boolean(mailer_options.is_preview),
      submission_reference: mailer_options.submission_reference,
      include_payment_link: make_notify_boolean(mailer_options.payment_url.present?),
      payment_link: mailer_options.payment_url || "",
    )

    set_reference(notify_response_id)

    set_email_reply_to(Settings.govuk_notify.form_submission_email_reply_to_id)

    mail(to: confirmation_email_address)
  end

private

  def default_what_happens_next_text
    I18n.t("mailer.submission_confirmation.default_what_happens_next")
  end

  def default_support_contact_details_text
    I18n.t("mailer.submission_confirmation.default_support_contact_details")
  end

  def make_notify_boolean(bool)
    bool ? "yes" : "no"
  end

  def template_id
    return Settings.govuk_notify.form_filler_confirmation_email_welsh_template_id if I18n.locale == :cy

    Settings.govuk_notify.form_filler_confirmation_email_template_id
  end
end
