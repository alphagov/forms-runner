class AwsSesFormSubmissionMailer < ApplicationMailer
  default from: I18n.t("mailer.submission.from", email_address: Settings.ses_submission_email.from_email_address),
          reply_to: Settings.ses_submission_email.reply_to_email_address,
          delivery_method: Rails.configuration.x.aws_ses_form_submission_mailer["delivery_method"]

  def submission_email(answer_content_html:, answer_content_plain_text:, submission:, files:, csv_filename: nil)
    @answer_content_html = answer_content_html
    @answer_content_plain_text = answer_content_plain_text
    @submission = submission
    @subject = email_subject
    @csv_filename = csv_filename

    files.each do |name, file|
      attachments[name] = {
        encoding: "base64",
        content: Base64.encode64(file),
      }
    end

    mail(to: submission.form.submission_email, subject: @subject)
  end

private

  def email_subject
    return I18n.t("mailer.submission.subject_preview", form_title: @submission.form.name, reference: @submission.reference) if @submission.preview?

    I18n.t("mailer.submission.subject", form_title: @submission.form.name, reference: @submission.reference)
  end
end
