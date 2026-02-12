class AwsSesSubmissionBatchMailer < ApplicationMailer
  default from: I18n.t("mailer.submission.from", email_address: Settings.ses_submission_email.from_email_address),
          reply_to: Settings.ses_submission_email.reply_to_email_address,
          delivery_method: Rails.configuration.x.aws_ses_form_submission_mailer["delivery_method"]

  def batch_submission_email(form:, date:, mode:, files:)
    @form = form
    @date = date.strftime("%-d %B %Y")
    @mode = mode

    files.each do |name, file|
      attachments[name] = {
        encoding: "base64",
        content: Base64.encode64(file),
      }
    end

    mail(to: form.submission_email, subject: batch_email_subject)
  end

private

  def batch_email_subject
    return I18n.t("mailer.submission_batch.subject_preview", form_name: @form.name, date: @date) if @mode.preview?

    I18n.t("mailer.submission_batch.subject", form_name: @form.name, date: @date)
  end
end
