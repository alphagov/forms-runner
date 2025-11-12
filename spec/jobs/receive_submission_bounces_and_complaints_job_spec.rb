require "rails_helper"

# rubocop:disable RSpec/InstanceVariable
RSpec.describe ReceiveSubmissionBouncesAndComplaintsJob, type: :job do
  include ActiveJob::TestHelper

  let(:sqs_client) { instance_double(Aws::SQS::Client) }
  let(:receipt_handle) { "bounce-receipt-handle" }
  let(:sqs_message_id) { "sqs-message-id" }
  let(:sqs_message) { instance_double(Aws::SQS::Types::Message, message_id: sqs_message_id, receipt_handle:, body: sns_message_body) }
  let(:messages) { [] }
  let(:sns_message_timestamp) { "2025-05-09T10:25:43.972Z" }
  let(:sns_message_body) { { "Message" => ses_message_body.to_json, "Timestamp" => sns_message_timestamp }.to_json }
  let(:event_type) { "Bounce" }
  let(:ses_message_body) { { "mail" => { "messageId" => mail_message_id }, "eventType": event_type } }
  let(:file_upload_steps) do
    [
      build(:v2_question_page_step, answer_type: "file", id: 1, next_step_id: 2),
      build(:v2_question_page_step, answer_type: "file", id: 2),
    ]
  end
  let(:form_with_file_upload) { build :v2_form_document, form_id: 1, steps: file_upload_steps, start_page: 1 }
  let(:form_with_file_upload_answers) do
    {
      "1" => { uploaded_file_key: "key1" },
      "2" => { uploaded_file_key: "key2" },
    }
  end
  let(:mail_message_id) { "mail-message-id" }
  let(:reference) { "submission-reference" }
  let!(:submission) { create :submission, mail_message_id:, reference:, form_id: form_with_file_upload.form_id, form_document: form_with_file_upload, answers: form_with_file_upload_answers }
  let!(:other_submission) { create :submission, mail_message_id: "abc", delivery_status: :pending, reference: "other-submission-reference", form_id: 2, answers: form_with_file_upload_answers }

  let(:output) { StringIO.new }
  let(:logger) do
    ApplicationLogger.new(output).tap do |logger|
      logger.formatter = JsonLogFormatter.new
    end
  end

  before do
    sts_client = instance_double(Aws::STS::Client)
    allow(Aws::STS::Client).to receive(:new).and_return(sts_client)
    allow(sts_client).to receive(:get_caller_identity).and_return(OpenStruct.new(account: "123456789012"))

    allow(Aws::SQS::Client).to receive(:new).and_return(sqs_client)
    allow(sqs_client).to receive(:receive_message).and_return(OpenStruct.new(messages: messages), OpenStruct.new(messages: []))
    allow(sqs_client).to receive(:delete_message)

    allow(CloudWatchService).to receive(:record_job_started_metric)

    Rails.logger.broadcast_to logger
  end

  after do
    Rails.logger.stop_broadcasting_to logger
  end

  describe "CloudWatch metrics" do
    let(:messages) { [sqs_message] }

    it "sends job started metric" do
      described_class.perform_now
      expect(CloudWatchService).to have_received(:record_job_started_metric).with("ReceiveSubmissionBouncesAndComplaintsJob")
    end
  end

  describe "processing bounce notifications" do
    let(:messages) { [sqs_message] }

    before do
      job = described_class.perform_later
      @job_id = job.job_id
    end

    context "when it is for a live submission" do
      it "updates the submission mail status to bounced" do
        perform_enqueued_jobs
        expect(submission.reload.bounced?).to be true
      end

      it "doesn't change the mail status for other submissions" do
        perform_enqueued_jobs
        expect(other_submission.reload.pending?).to be true
      end

      it "logs form event with correct details" do
        perform_enqueued_jobs

        expect(log_lines).to include(hash_including(
                                       "level" => "INFO",
                                       "message" => "Form event",
                                       "event" => "form_submission_bounced",
                                       "form_id" => form_with_file_upload.form_id,
                                       "submission_reference" => reference,
                                       "preview" => "false",
                                       "mail_message_id" => mail_message_id,
                                       "sqs_message_id" => sqs_message_id,
                                       "sns_message_timestamp" => sns_message_timestamp,
                                       "job_id" => @job_id,
                                       "job_class" => "ReceiveSubmissionBouncesAndComplaintsJob",
                                     ))
      end

      it "alerts to Sentry that there was a bounced delivery" do
        allow(Sentry).to receive(:capture_message)
        perform_enqueued_jobs
        expect(Sentry).to have_received(:capture_message)
      end
    end

    context "when it is for a preview submission" do
      let!(:submission) do
        create :submission,
               mail_message_id:,
               reference:,
               form_id: form_with_file_upload.form_id,
               form_document: form_with_file_upload,
               answers: form_with_file_upload_answers,
               mode: "preview-live"
      end

      it "does not update the submission mail status to bounced" do
        perform_enqueued_jobs
        expect(submission.reload.bounced?).to be false
      end

      it "logs form event with preview flag" do
        perform_enqueued_jobs

        expect(log_lines).to include(hash_including(
                                       "level" => "INFO",
                                       "message" => "Form event",
                                       "event" => "form_submission_bounced",
                                       "preview" => "true",
                                     ))
      end

      it "does not alert to Sentry" do
        allow(Sentry).to receive(:capture_message)
        perform_enqueued_jobs
        expect(Sentry).not_to have_received(:capture_message)
      end
    end

    context "when there is a bounce object with detailed information" do
      let(:ses_message_body) { { "mail" => { "messageId" => mail_message_id }, "eventType" => event_type, "bounce" => bounce } }
      let(:bounce) { { "bounceType" => "Permanent", "bounceSubType" => "General", "bouncedRecipients" => bounced_recipients } }
      let(:bounced_recipients) { [{ "emailAddress" => "bounce@example.com" }] }

      it "logs the bounce details" do
        perform_enqueued_jobs

        expect(log_lines).to include(
          hash_including(
            "ses_bounce" => hash_including(
              "bounce_type" => "Permanent",
              "bounce_sub_type" => "General",
              "bounced_recipients" => [
                hash_including(
                  "email_address" => "bounce@example.com",
                ),
              ],
            ),
          ),
        )
      end

      it "includes bounce details in the Sentry event" do
        allow(Sentry).to receive(:capture_message)
        perform_enqueued_jobs
        expect(Sentry).to have_received(:capture_message).with(
          a_string_including("Submission email bounced for form 1 - ReceiveSubmissionBouncesAndComplaintsJob"),
          fingerprint: ["{{ default }}", submission.form_id],
          extra: hash_including(
            ses_bounce: hash_including(
              bounce_type: "Permanent",
              bounce_sub_type: "General",
            ),
          ),
        )
      end

      it "does not include bounced recipients in the Sentry event" do
        allow(Sentry).to receive(:capture_message)
        perform_enqueued_jobs
        expect(Sentry).not_to have_received(:capture_message).with(
          anything,
          extra: hash_including(
            ses_bounce: hash_including(
              :bounced_recipients,
            ),
          ),
        )
      end
    end
  end

  describe "processing complaint notifications" do
    let(:event_type) { "Complaint" }
    let(:messages) { [sqs_message] }

    before do
      job = described_class.perform_later
      @job_id = job.job_id
    end

    it "logs complaint event with correct details" do
      perform_enqueued_jobs

      expect(log_lines).to include(hash_including(
                                     "level" => "INFO",
                                     "form_id" => form_with_file_upload.form_id,
                                     "submission_reference" => reference,
                                     "preview" => "false",
                                     "message" => "Form event",
                                     "event" => "form_submission_complaint",
                                     "job_id" => @job_id,
                                     "job_class" => "ReceiveSubmissionBouncesAndComplaintsJob",
                                   ))
    end
  end

  describe "handling unexpected event types" do
    let(:event_type) { "Some other event type" }
    let(:messages) { [sqs_message] }

    it "raises an error with the unexpected event type" do
      allow(Sentry).to receive(:capture_exception)

      described_class.perform_now

      expect(Sentry).to have_received(:capture_exception) do |error|
        expect(error.message).to eq("Unexpected event type:#{event_type}")
      end
    end
  end

  def log_lines
    output.string.split("\n").map { |line| JSON.parse(line) }
  end
end
# rubocop:enable RSpec/InstanceVariable
