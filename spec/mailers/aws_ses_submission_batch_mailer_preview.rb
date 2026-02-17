class AwsSesSubmissionBatchMailerPreview < ActionMailer::Preview
  include FactoryBot::Syntax::Methods

  def batch_submission_email
    form = build(:form, submission_email: "testing@gov.uk")
    AwsSesSubmissionBatchMailer.batch_submission_email(form:,
                                                       date: Time.zone.now,
                                                       mode: Mode.new("form"),
                                                       files: { "batch.csv" => "Hello world" })
  end

  def batch_submission_email_preview
    form = build(:form, submission_email: "testing@gov.uk")
    AwsSesSubmissionBatchMailer.batch_submission_email(form:,
                                                       date: Time.zone.now,
                                                       mode: Mode.new("preview-draft"),
                                                       files: { "batch.csv" => "Hello world" })
  end

  def batch_submission_with_multiple_files
    form = build(:form, submission_email: "testing@gov.uk")
    AwsSesSubmissionBatchMailer.batch_submission_email(form:,
                                                       date: Time.zone.now,
                                                       mode: Mode.new("form"),
                                                       files: {
                                                         "batch.csv" => "Hello world",
                                                         "batch_2.csv" => "Hello again",
                                                       })
  end
end
