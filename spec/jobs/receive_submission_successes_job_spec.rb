require "rails_helper"

# rubocop:disable RSpec/InstanceVariable
RSpec.describe ReceiveSubmissionSuccessesJob, type: :job do
  include ActiveJob::TestHelper

  let(:sqs_client) { instance_double(Aws::SQS::Client) }
  let(:receipt_handle) { "delivery-receipt-handle" }
  let(:sqs_message_id) { "sqs-message-id" }
  let(:sqs_delivery_message) { instance_double(Aws::SQS::Types::Message, message_id: sqs_message_id, receipt_handle:, body: sns_delivery_message_body) }
  let(:messages) { [] }
  let(:sns_delivery_message_body) { { "Message" => ses_delivery_message_body.to_json }.to_json }
  let(:ses_delivery_message_body) { { "mail" => { "messageId" => mail_message_id }, "eventType": "Delivery" } }
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
  let!(:other_submission) { create :submission, mail_message_id: "abc", mail_status: "fine", reference: "other-submission-reference", form_id: 2, answers: form_with_file_upload_answers }

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

      allow(Aws::SQS::Client).to receive(:new).and_return(sqs_client)
      allow(sqs_client).to receive(:receive_message).and_return(OpenStruct.new(messages: messages), OpenStruct.new(messages: []))
      allow(sqs_client).to receive(:delete_message) do
        messages.shift
      end
      Rails.logger.broadcast_to logger
    end

    after do
      Rails.logger.stop_broadcasting_to logger
    end

    context "when there are many messages in the queue" do
      let(:message_count) { 15 }
      let(:messages) { Array.new(message_count, sqs_delivery_message) }

      before do
        allow(sqs_client).to receive(:receive_message).and_return(OpenStruct.new(messages: messages[0..9]), OpenStruct.new(messages: messages[10..15]), OpenStruct.new(messages: []))

        described_class.perform_later
      end

      it "clears the SQS queue" do
        perform_enqueued_jobs
        expect(sqs_client).to have_received(:delete_message).exactly(message_count).times
      end
    end

    context "when the message is a delivery notification" do
      let(:messages) { [sqs_delivery_message] }

      before do
        job = described_class.perform_later
        @job_id = job.job_id
      end

      it "updates the submission mail status to delivered" do
        perform_enqueued_jobs
        expect(submission.reload.mail_status).to eq("delivered")
      end

      it "doesn't change the mail status for other submissions" do
        perform_enqueued_jobs
        expect(other_submission.reload.mail_status).to eq("fine")
      end

      it "logs at info level" do
        perform_enqueued_jobs

        expect(log_lines).to include(hash_including(
                                       "level" => "INFO",
                                       "message" => "Submission email delivered - ReceiveSubmissionSuccessesJob",
                                       "form_id" => form_with_file_upload.id,
                                       "submission_reference" => reference,
                                       "job_id" => @job_id,
                                     ))
      end

      context "when there is no submission found" do
        let(:ses_delivery_message_body) { { "mail" => { "messageId" => "mismatched-message-id" }, "eventType": "Delivery" } }

        it "sends an error to Sentry" do
          allow(Sentry).to receive(:capture_exception)

          perform_enqueued_jobs

          expect(Sentry).to have_received(:capture_exception) do |error|
            expect(error.message).to eq("Submission not found for SES message ID: mismatched-message-id")
          end
        end
      end

      context "when updating submission fails" do
        before do
          allow(Submission).to receive(:find_by).and_raise(StandardError, "Test error")
        end

        it "logs at warn level" do
          begin
            perform_enqueued_jobs
          rescue StandardError
            nil
          end

          expect(log_lines).to include(hash_including(
                                         "level" => "WARN",
                                         "mail_message_id" => mail_message_id,
                                         "sqs_message_id" => sqs_message_id,
                                         "message" => "Error processing message - StandardError: Test error",
                                         "job_id" => @job_id,
                                       ))
        end

        it "sends an error to Sentry" do
          allow(Sentry).to receive(:capture_exception)

          perform_enqueued_jobs

          expect(Sentry).to have_received(:capture_exception)
        end
      end

      it "deletes the SQS message" do
        perform_enqueued_jobs
        expect(sqs_client).to have_received(:delete_message).with(queue_url: anything, receipt_handle:)
      end
    end
  end

  def log_lines
    output.string.split("\n").map { |line| JSON.parse(line) }
  end
end
# rubocop:enable RSpec/InstanceVariable
