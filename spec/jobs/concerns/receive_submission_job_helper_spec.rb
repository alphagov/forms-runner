require "rails_helper"

class DummyJob < ApplicationJob
  include ReceiveSubmissionJobHelper

  SQS_QUEUE_NAME = "dummy_queue".freeze

  def process_ses_event(ses_event_type, submission) end
end

RSpec.describe ReceiveSubmissionJobHelper, type: :helper do
  let(:dummy_job) { DummyJob.new }
  let(:sqs_client) { instance_double(Aws::SQS::Client) }
  let(:receipt_handle) { "delivery-receipt-handle" }
  let(:sqs_message_id) { "sqs-message-id" }
  let(:ses_event_type) { "Delivery" }
  let(:sqs_message) { instance_double(Aws::SQS::Types::Message, message_id: sqs_message_id, receipt_handle:, body: sns_delivery_message_body) }
  let(:messages) { [] }
  let(:sns_delivery_message_body) { { "Message" => ses_delivery_message_body.to_json }.to_json }
  let(:ses_delivery_message_body) { { "mail" => { "messageId" => mail_message_id }, "eventType": ses_event_type } }
  let(:file_upload_steps) do
    [
      build(:v2_question_page_step, answer_type: "file", id: 1, next_step_id: 2),
      build(:v2_question_page_step, answer_type: "file", id: 2),
    ]
  end
  let(:form_with_file_upload) { build :v2_form_document, id: 1, steps: file_upload_steps, start_page: 1 }
  let(:form_with_file_upload_answers) do
    {
      "1" => { uploaded_file_key: "key1" },
      "2" => { uploaded_file_key: "key2" },
    }
  end
  let(:mail_message_id) { "mail-message-id" }
  let(:reference) { "submission-reference" }
  let!(:submission) { create :submission, mail_message_id:, reference:, form_id: form_with_file_upload.id, form_document: form_with_file_upload, answers: form_with_file_upload_answers }

  let(:output) { StringIO.new }
  let(:logger) do
    ApplicationLogger.new(output).tap do |logger|
      logger.formatter = JsonLogFormatter.new
    end
  end

  context "when there are messages in the queue" do
    before do
      sts_client = instance_double(Aws::STS::Client)
      allow(Aws::STS::Client).to receive(:new).and_return(sts_client)
      allow(sts_client).to receive(:get_caller_identity).and_return(OpenStruct.new(account: "123456789012"))
      allow(dummy_job).to receive(:process_ses_event)

      allow(Aws::SQS::Client).to receive(:new).and_return(sqs_client)
      # allow(sqs_client).to receive(:receive_message).and_return(OpenStruct.new(messages: messages), OpenStruct.new(messages: []))
      allow(sqs_client).to receive(:receive_message).and_return(OpenStruct.new(messages: messages[0..9]), OpenStruct.new(messages: messages[10..15]), OpenStruct.new(messages: []))
      allow(sqs_client).to receive(:delete_message) do
        messages.shift
      end

      allow(CloudWatchService).to receive(:log_job_started)

      Rails.logger.broadcast_to logger
    end

    after do
      Rails.logger.stop_broadcasting_to logger
    end

    let(:message_count) { 15 }
    let(:messages) { Array.new(message_count, sqs_message) }

    it "sends CloudWatch metric" do
      dummy_job.perform
      expect(CloudWatchService).to have_received(:log_job_started).with("DummyJob")
    end

    it "processes SES events" do
      dummy_job.perform
      expect(dummy_job).to have_received(:process_ses_event).with(ses_event_type, submission).exactly(message_count).times
    end

    it "deletes processed SQS messages" do
      dummy_job.perform
      expect(sqs_client).to have_received(:delete_message).exactly(message_count).times
    end

    context "when there is no submission found" do
      let(:ses_delivery_message_body_mismatched) { { "mail" => { "messageId" => "mismatched_message_id" }, "eventType": ses_event_type } }
      let(:sns_delivery_message_body_mismatched) { { "Message" => ses_delivery_message_body_mismatched.to_json }.to_json }
      let(:sqs_message_mismatched) { instance_double(Aws::SQS::Types::Message, message_id: sqs_message_id, receipt_handle:, body: sns_delivery_message_body_mismatched) }
      let(:messages) { Array.new(1, sqs_message_mismatched) }

      before do
        allow(sqs_client).to receive(:receive_message).and_return(OpenStruct.new(messages:), OpenStruct.new(messages: []))
      end

      it "sends an error to Sentry" do
        allow(Sentry).to receive(:capture_exception)

        dummy_job.perform

        expect(Sentry).to have_received(:capture_exception).at_least(1).times do |error|
          expect(error.class).to eq(ActiveRecord::RecordNotFound)
        end
      end

      it "does not process the SES event" do
        dummy_job.perform

        expect(dummy_job).not_to have_received(:process_ses_event)
      end

      it "does not delete the SQS message" do
        dummy_job.perform

        expect(sqs_client).not_to have_received(:delete_message)
      end

      context "fuck" do
        let(:messages) { Array.new(1, sqs_message_mismatched) + Array.new(1, sqs_message) }

        it "continues processing subsequent messages" do
          expected_loop_count = messages.length - 1

          dummy_job.perform

          expect(sqs_client).to have_received(:delete_message).exactly(expected_loop_count).times
        end
      end
    end

    context "when processing an SES event fails" do
      let(:messages) { [sqs_message, sqs_message] }

      before do
        call_count = 0

        allow(Submission).to receive(:find_by) do
          call_count += 1
          if call_count == 1
            raise StandardError, "Test error"
          else
            submission
          end
        end
        allow(sqs_client).to receive(:receive_message).and_return(OpenStruct.new(messages:), OpenStruct.new(messages: []))
      end

      it "does not delete the SQS message" do
        dummy_job.perform

        expect(sqs_client).not_to have_received(:delete_message)
      end

      it "continues processing subsequent messages" do
        expected_loop_count = messages.length - 1

        dummy_job.perform

        expect(sqs_client).to have_received(:delete_message).exactly(expected_loop_count).times
      end
    end
  end

  def log_lines
    output.string.split("\n").map { |line| JSON.parse(line) }
  end
end
