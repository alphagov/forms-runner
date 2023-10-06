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
      test: make_notify_boolean(preview_mode),
      not_test: make_notify_boolean(!preview_mode),
    )

    set_reference(reference)

    set_email_reply_to(Settings.govuk_notify.form_submission_email_reply_to_id)
    begin
      mail(to: submission_email)
    rescue RequestError
      raise StandardError, "Sending submission email error. Reference #{reference}"
    end
  end

private

  def make_notify_boolean(bool)
    bool ? "yes" : "no"
  end
end
