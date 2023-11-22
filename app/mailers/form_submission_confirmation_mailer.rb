class FormSubmissionConfirmationMailer < GovukNotifyRails::Mailer
  def send_confirmation_email(title:, what_happens_next_text:, support_contact_details:, submission_timestamp:, preview_mode:, reference:, confirmation_email_address:)
    set_template(Settings.govuk_notify.form_filler_confirmation_email_template_id)

    set_personalisation(
      title:,
      what_happens_next_text:,
      support_contact_details:,
      submission_time: submission_timestamp.strftime("%l:%M%P").strip,
      submission_date: submission_timestamp.strftime("%-d %B %Y"),
      # GOV.UK Notify's templates have conditionals, but only positive
      # conditionals, so to simulate negative conditionals we add two boolean
      # flags; but they must always have opposite values!
      test: make_notify_boolean(preview_mode),
    )

    set_reference(reference)

    set_email_reply_to(Settings.govuk_notify.form_submission_email_reply_to_id)

    mail(to: confirmation_email_address)
  end

private

  def make_notify_boolean(bool)
    bool ? "yes" : "no"
  end
end
