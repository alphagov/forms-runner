class FormSubmissionMailer < GovukNotifyRails::Mailer
  def email_completed_form(title:, text_input:, reference:, timestamp:, submission_email:)
    set_template(Settings.govuk_notify.form_submission_email_template_id)

    set_personalisation(
      title:,
      text_input:,
      submission_time: timestamp.strftime("%H:%M:%S"),
      submission_date: timestamp.strftime("%-d %B %Y"),
    )

    set_reference(reference)

    mail(to: submission_email)
  end
end
