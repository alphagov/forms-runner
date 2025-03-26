require "rails_helper"

# rubocop:disable RSpec/InstanceVariable
RSpec.describe SendSubmissionJob, type: :job do
  include ActiveJob::TestHelper

  let(:submission) { create :submission, form_document: form, mail_status: :pending }
  let(:form) { build(:form, id: 1, name: "Form 1") }
  let(:question) { build :text, question_text: "What is the meaning of life?", text: "42" }
  let(:step) { build :step, question: }
  let(:all_steps) { [step] }
  let(:journey) { instance_double(Flow::Journey, completed_steps: all_steps, all_steps:) }
  let(:aws_ses_submission_service_spy) { instance_double(AwsSesSubmissionService) }
  let(:mail_message_id) { "1234" }
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
    allow(Flow::Journey).to receive(:new).and_return(journey)
    allow(AwsSesSubmissionService).to receive(:new).with(form:, journey:, mailer_options:).and_return(aws_ses_submission_service_spy)
    allow(CloudWatchService).to receive(:log_submission_sent)
  end

  context "when the job is processed" do
    before do
      allow(aws_ses_submission_service_spy).to receive(:submit).and_return(mail_message_id)

      described_class.perform_later(submission)
      travel 5.seconds do
        @job_ran_at = Time.zone.now
        perform_enqueued_jobs
      end
    end

    it "submits via AWS SES" do
      expect(aws_ses_submission_service_spy).to have_received(:submit)
    end

    it "updates the submission message ID" do
      expect(Submission.last).to have_attributes(mail_message_id:)
    end

    it "updates the submission mail status to pending" do
      expect(Submission.last.pending?).to be true
    end

    it "updates the sent at time" do
      expect(submission.reload.sent_at).to be_within(1.second).of(@job_ran_at)
    end

    it "sends cloudwatch metric for the submission being sent" do
      expect(CloudWatchService).to have_received(:log_submission_sent).with(be_within(1000).of(5000))
    end
  end

  context "when there is an error during processing" do
    context "and the error is an Aws::SESV2::Errors::ServiceError" do
      before do
        allow(aws_ses_submission_service_spy).to receive(:submit).and_raise(Aws::SESV2::Errors::ServiceError.new(nil, "Test SES error", nil))
        allow(CloudWatchService).to receive(:log_job_failure)
      end

      it "retries for the configured number of attempts" do
        assert_performed_jobs SendSubmissionJob::TOTAL_ATTEMPTS do
          described_class.perform_later(submission)
        rescue Aws::SESV2::Errors::ServiceError # If we don't catch the error, the test aborts prematurely
          nil
        end
      end

      it "raises an error after all attempts fail" do
        expect { described_class.new.perform(submission) }.to raise_error(Aws::SESV2::Errors::ServiceError)
      end

      it "sends cloudwatch metric for failure" do
        described_class.new.perform(submission)
        expect(CloudWatchService).to have_received(:log_job_failure).with("SendSubmissionJob")
      rescue Aws::SESV2::Errors::ServiceError # If we don't catch the error, the test aborts prematurely
        nil
      end
    end

    context "and the error is any other error" do
      before do
        allow(aws_ses_submission_service_spy).to receive(:submit).and_raise(StandardError, "Test error")
      end

      it "doesn't retry" do
        assert_performed_jobs 1 do
          described_class.perform_later(submission)
        rescue StandardError # If we don't catch the error, the test aborts prematurely
          nil
        end
      end

      it "raises an error immediately" do
        expect { described_class.new.perform(submission) }.to raise_error(StandardError)
      end

      it "sends cloudwatch metric for failure" do
        described_class.new.perform(submission)
        expect(CloudWatchService).to have_received(:log_job_failure).with("SendSubmissionJob")
      rescue StandardError # If we don't catch the error, the test aborts prematurely
        nil
      end
    end
  end
end
# rubocop:enable RSpec/InstanceVariable
