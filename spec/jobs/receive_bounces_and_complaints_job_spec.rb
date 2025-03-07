require "rails_helper"

RSpec.describe ReceiveBouncesAndComplaintsJob, type: :job do
  include ActiveJob::TestHelper

  context "when there are messages in the queue" do
    context "when the message is a bounce notification" do
      let(:sqs_client) { instance_double(Aws::SQS::Client) }
      let(:sts_client) { instance_double(Aws::STS::Client) }
      let(:receipt_handle){"bounce-receipt-handle"}
      let(:sqs_bounce_message) { instance_double(Aws::SQS::Types::Message, receipt_handle:, body: sns_bounce_message_body) }
      let(:sqs_complaint_message) { instance_double(Aws::SQS::Types::Message, receipt_handle: "complaint-receipt-handle", body: sns_complaint_message_body) }
      let(:messages) { [sqs_bounce_message, sqs_complaint_message] }
      let(:sns_bounce_message_body) { { "Message" => ses_bounce_message_body.to_json }.to_json }
      let(:sns_complaint_message_body) { { "Message" => ses_complaint_message_body.to_json }.to_json }
      let(:ses_bounce_message_body) { { "mail" => { "messageId" => mail_message_id }, "notificationType": "Bounce" } }
      let(:ses_complaint_message_body) { { "mail" => { "messageId" => mail_message_id }, "notificationType": "Complaint" } }
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
      let!(:submission) { create :submission, mail_message_id:, reference:, form_id: form_with_file_upload.id, answers: form_with_file_upload_answers }
      let!(:other_submission) { create :submission, mail_message_id: "abc", mail_status: "fine", reference: "other-submission-reference", form_id: 2, answers: form_with_file_upload_answers }

      before do
        allow(sts_client).to receive(:get_caller_identity).and_return(OpenStruct.new(account: "123456789012"))
        allow(Aws::STS::Client).to receive(:new).and_return(sts_client)
        allow(Aws::SQS::Client).to receive(:new).and_return(sqs_client)
        allow(sqs_client).to receive(:receive_message).and_return(OpenStruct.new(messages: messages))
        allow(sqs_client).to receive(:delete_message)
        allow(Rails.logger).to receive(:info).at_least(:once)

        described_class.perform_later
      end

      it "updates the submission mail status to bounced" do
        perform_enqueued_jobs
        expect(submission.reload.mail_status).to eq("bounced")
      end

      it "doesn't change the mail status for other submissions" do
        perform_enqueued_jobs
        expect(other_submission.reload.mail_status).to eq("fine")
      end

      it "logs at info level" do
        perform_enqueued_jobs
        expect(Rails.logger).to have_received(:info).with("Updated submission mail status to bounced - ReceiveBouncesAndComplaintsJob:", {
          form_id: form_with_file_upload.id,
          submission_reference: reference,
          job_id: anything,
        })
      end

      context "when updating submission fails" do
        before do
          allow(Submission).to receive(:find_by).and_raise(StandardError, "Test error")
          allow(Rails.logger).to receive(:warn).at_least(:once)
          allow(Sentry).to receive(:capture_exception)
        end

        it "logs at warn level" do
          perform_enqueued_jobs
          expect(Rails.logger).to have_received(:warn).with("Error updating submission mail status - StandardError: Test error", {
            job_id: anything,
          })
        end

        it "sends error to Sentry" do
          perform_enqueued_jobs
          expect(Sentry).to have_received(:capture_exception)
        end
      end

      skip "extends the retention period for S3 objects" do
      end

      it "alerts to Sentry that there was a bounced delivery" do
        allow(Sentry).to receive(:capture_message)
        perform_enqueued_jobs
        expect(Sentry).to have_received(:capture_message)
      end

      it "deletes the SQS message" do
        perform_enqueued_jobs
        expect(sqs_client).to have_received(:delete_message).with(queue_url: anything, receipt_handle:)
      end

      it "logs SQS message deletion at info level" do
        perform_enqueued_jobs
        expect(Rails.logger).to have_received(:info).with("Message deleted successfully - ReceiveBouncesAndComplaintsJob:", {
          job_id: anything,
          receipt_handle:,
        })
      end

      context "when SQS message deletion fails" do
        before do
          allow(sqs_client).to receive(:delete_message).and_raise(StandardError, "Test error")
          allow(Rails.logger).to receive(:warn).at_least(:once)
          allow(Sentry).to receive(:capture_exception)
        end

        it "logs at warn level" do
          perform_enqueued_jobs
          expect(Rails.logger).to have_received(:warn).with("Error deleting SQS message - StandardError: Test error", {
            job_id: anything,
            receipt_handle:,
          })
        end

        it "sends error to Sentry" do
          perform_enqueued_jobs
          expect(Sentry).to have_received(:capture_exception)
        end
      end
    end

    context "when the message is a complaint notification" do
      skip "logs that there was a complaint" do
      end

      skip "deletes the message" do
      end
    end
  end

  context "when there are no messages in the queue" do
    skip "logs that there are no message to process" do
    end
  end
end
