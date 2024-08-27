class AwsSesMailer < ApplicationMailer
  default from: "GOV.UK Forms <submissions@dev.forms.service.gov.uk>",
          reply_to: "govuk-forms-noreply@digital.cabinet-office.gov.uk",
          delivery_method: :aws_ses

  def submission_with_csv_email(answer_content:, submission_email:, mailer_options:, csv_file:)
    @answer_content = answer_content
    @mailer_options = mailer_options
    @subject = "Form submission: #{mailer_options.title} - reference: #{mailer_options.submission_reference}"

    attachments[csv_filename(mailer_options)] = File.read(csv_file.path) if csv_file.present?

    mail(to: submission_email, subject: @subject)
  end

  def csv_filename(mailer_options)
    title_part = mailer_options.title.parameterize(separator: "_")
    reference = mailer_options.submission_reference
    "govuk_forms_submission_#{title_part}_#{reference}.csv"
  end
end
