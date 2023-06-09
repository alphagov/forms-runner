class FormSubmissionMailer < GovukNotifyRails::Mailer
  def email_completed_form(title:, text_input:, reference:, preview_mode:, timestamp:, submission_email:)
    set_template(Settings.govuk_notify.form_submission_email_template_id)

    set_personalisation(
      title:,
      text_input:,
      submission_time: timestamp.strftime("%H:%M:%S"),
      submission_date: timestamp.strftime("%-d %B %Y"),
      # GOV.UK Notify's templates have conditionals, but only positive
      # conditionals, so to simulate negative conditionals we add two boolean
      # flags; but they must always have opposite values!
      test: preview_mode ? "yes" : "no",
      not_test: preview_mode ? "no" : "yes",
    )

    set_reference(reference)

    set_email_reply_to(Settings.govuk_notify.form_submission_email_reply_to_id)

    mail(to: submission_email)
  end
end
