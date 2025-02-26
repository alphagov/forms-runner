require "rails_helper"

RSpec.describe SendSubmissionJob, type: :job do
  include ActiveJob::TestHelper

  let(:submission) { create :submission }
  let(:form) { build(:form, id: 1, name: "Form 1") }
  let(:question) { build :text, question_text: "What is the meaning of life?", text: "42" }
  let(:step) { build :step, question: }
  let(:all_steps) { [step] }
  let(:journey) { instance_double(Flow::Journey, completed_steps: all_steps, all_steps:) }
  let(:aws_ses_submission_service_spy) { instance_double(AwsSesSubmissionService) }
  let(:mail_message_id) { "1234" }
  let(:req_headers) do
    {
      "X-API-Token" => Settings.forms_api.auth_key,
      "Accept" => "application/json",
    }
  end
  let(:mailer_options) do
    FormSubmissionService::MailerOptions.new(
      title: form.name,
      is_preview: false,
      timestamp: submission.created_at,
      submission_reference: submission.reference,
      payment_url: form.payment_url_with_reference(submission.reference),
    )
  end


  before do
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get "/api/v2/forms/1/live", req_headers, form.to_json, 200
    end

    allow(Flow::Journey).to receive(:new).and_return(journey)
    allow(AwsSesSubmissionService).to receive(:new).with(form:, journey:, mailer_options:).and_return(aws_ses_submission_service_spy)
    allow(aws_ses_submission_service_spy).to receive(:submit).and_return(mail_message_id)

    perform_enqueued_jobs do
      described_class.perform_later(submission)
    end
  end

  it "submits via AWS SES" do
    expect(aws_ses_submission_service_spy).to have_received(:submit)
  end

  it "updates the submission message ID" do
    expect(Submission.last).to have_attributes(mail_message_id:)
  end
end
