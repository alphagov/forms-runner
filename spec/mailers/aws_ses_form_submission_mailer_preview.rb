class AwsSesFormSubmissionMailerPreview < ActionMailer::Preview
  def submission_email
    AwsSesFormSubmissionMailer.submission_email(answer_content_html: "<h2>What's your email address?</h2><p>forms@example.gov.uk</p>",
                                                answer_content_plain_text: "<h2>What's your email address?</h2><p>forms@example.gov.uk</p>",
                                                submission_email_address: "testing@gov.uk",
                                                mailer_options: FormSubmissionService::MailerOptions.new(title: "Form 1",
                                                                                                         is_preview: false,
                                                                                                         timestamp: Time.zone.now,
                                                                                                         submission_reference: Faker::Alphanumeric.alphanumeric(number: 8).upcase,
                                                                                                         payment_url: nil),
                                                files: {})
  end
end
