class AwsSesFormSubmissionMailer < ApplicationMailer
  class AttachmentMismatchError < StandardError
    def message
      "Number of files attached does not match number of files passed in"
    end
  end

  default from: I18n.t("mailer.submission.from", email_address: Settings.ses_submission_email.from_email_address),
          reply_to: Settings.ses_submission_email.reply_to_email_address,
          delivery_method: Rails.configuration.x.aws_ses_form_submission_mailer["delivery_method"]

  def submission_email(answer_content:, submission_email_address:, mailer_options:, files:)
    @answer_content = answer_content
    @mailer_options = mailer_options
    @subject = I18n.t("mailer.submission.subject", form_title: mailer_options.title, reference: mailer_options.submission_reference)

    files.each do |file|
      attachments[file[:name]] = file[:file]
    end

    raise AttachmentMismatchError if files.count != attachments.count

    mail(to: submission_email_address, subject: @subject)
  end
end
