class AwsSesFormSubmissionMailer < ApplicationMailer
  default from: I18n.t("mailer.submission.from", email_address: Settings.ses_submission_email.from_email_address),
          reply_to: Settings.ses_submission_email.reply_to_email_address,
          delivery_method: Rails.configuration.x.aws_ses_form_submission_mailer["delivery_method"]

  def submission_email(answer_content_html:, answer_content_plain_text:, submission_email_address:, mailer_options:, files:, csv_filename: nil)
    @answer_content_html = answer_content_html
    @answer_content_plain_text = answer_content_plain_text
    @mailer_options = mailer_options
    @subject = email_subject
    @csv_filename = csv_filename

    files.each do |name, file|
      attachments[name] = file
    end

    mail(to: submission_email_address, subject: @subject)
  end

private

  def email_subject
    return I18n.t("mailer.submission.subject_preview", form_title: @mailer_options.title, reference: @mailer_options.submission_reference) if @mailer_options.is_preview

    I18n.t("mailer.submission.subject", form_title: @mailer_options.title, reference: @mailer_options.submission_reference)
  end
end
