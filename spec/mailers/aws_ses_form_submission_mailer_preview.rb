class AwsSesFormSubmissionMailerPreview < ActionMailer::Preview
  include FactoryBot::Syntax::Methods

  def submission_email
    form_document = build(:v2_form_document, submission_email: "testing@gov.uk")
    submission = build(:submission, form_document:, is_preview: false)
    AwsSesFormSubmissionMailer.submission_email(answer_content_html: "<h3>What's your email address?</h3><p>forms@example.gov.uk</p>",
                                                answer_content_plain_text: "What's your email address?\n\nforms@example.gov.uk",
                                                submission:,
                                                files: {})
  end

  def preview_submission_email
    form_document = build(:v2_form_document, submission_email: "testing@gov.uk")
    submission = build(:submission, form_document:, is_preview: true)
    AwsSesFormSubmissionMailer.submission_email(answer_content_html: "<h3>What's your email address?</h3><p>forms@example.gov.uk</p>",
                                                answer_content_plain_text: "What's your email address?\n\nforms@example.gov.uk",
                                                submission:,
                                                files: {})
  end

  def submission_email_with_payment_link
    form_document = build(:v2_form_document, submission_email: "testing@gov.uk", payment_url: "https://www.gov.uk/payments/your-payment-link")
    submission = build(:submission, form_document:, is_preview: false)
    AwsSesFormSubmissionMailer.submission_email(answer_content_html: "<h3>What's your email address?</h3><p>forms@example.gov.uk</p>",
                                                answer_content_plain_text: "What's your email address?\n\nforms@example.gov.uk",
                                                submission:,
                                                files: {})
  end

  def submission_email_with_csv
    form_document = build(:v2_form_document, submission_email: "testing@gov.uk", payment_url: "https://www.gov.uk/payments/your-payment-link")
    submission = build(:submission, form_document:, is_preview: false)
    AwsSesFormSubmissionMailer.submission_email(answer_content_html: "<h3>What's your email address?</h3><p>forms@example.gov.uk</p>",
                                                answer_content_plain_text: "What's your email address?\n\nforms@example.gov.uk",
                                                submission:,
                                                files: {},
                                                csv_filename: "my_answers.csv")
  end
end
