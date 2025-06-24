require "rails_helper"

# rubocop:disable RSpec/InstanceVariable
RSpec.describe DeleteSubmissionsJob, type: :job do
  include ActiveJob::TestHelper

  let(:form_with_file_upload) { build :v2_form_document, id: 1, steps: file_upload_steps, start_page: 1 }
  let(:form_without_file_upload) { build :v2_form_document, id: 2, steps: [text_step], start_page: text_step.id }
  let(:file_upload_steps) do
    [
      build(:v2_question_page_step, answer_type: "file", id: 1, next_step_id: 2),
      build(:v2_question_page_step, answer_type: "file", id: 2),
    ]
  end
  let(:text_step) { build(:v2_question_page_step, :with_text_settings, id: 3) }

  let(:file_upload_s3_service_spy) { instance_double(Question::FileUploadS3Service) }

  let(:form_with_file_upload_answers) do
    {
      "1" => { uploaded_file_key: "key1", original_filename: "first_file.png" },
      "2" => { uploaded_file_key: "key2", original_filename: "second_file.txt" },
    }
  end

  let!(:sent_submission_sent_8_days_ago) do
    create :submission,
           :sent,
           reference: "SENT8DAYS",
           form_id: form_with_file_upload.id,
           form_document: form_with_file_upload,
           sent_at: 8.days.ago,
           answers: form_with_file_upload_answers
  end
  let!(:sent_submission_sent_7_days_ago) do
    create :submission,
           :sent,
           reference: "SENT7DAYS",
           form_id: form_without_file_upload.id,
           form_document: form_without_file_upload,
           sent_at: 7.days.ago
  end
  let!(:sent_submission_sent_6_days_ago) do
    create :submission,
           :sent,
           reference: "SENT6DAYS",
           form_id: form_without_file_upload.id,
           form_document: form_without_file_upload,
           sent_at: 6.days.ago
  end
  let!(:bounced_submission) do
    create :submission,
           :sent,
           reference: "BOUNCED",
           form_id: form_without_file_upload.id,
           form_document: form_without_file_upload,
           sent_at: 7.days.ago,
           mail_status: :bounced
  end
  let!(:unsent_submission) { create :submission, reference: "UNSENT", sent_at: nil }

  let(:output) { StringIO.new }
  let(:logger) do
    ApplicationLogger.new(output).tap do |logger|
      logger.formatter = JsonLogFormatter.new
    end
  end

  before do
    Rails.logger.broadcast_to logger

    allow(Question::FileUploadS3Service).to receive(:new).and_return(file_upload_s3_service_spy)
    allow(CloudWatchService).to receive(:record_job_started_metric)

    job = described_class.perform_later
    @job_id = job.job_id
  end

  after do
    Rails.logger.stop_broadcasting_to logger
  end

  context "when deleting uploaded files is successful" do
    before do
      allow(file_upload_s3_service_spy).to receive(:delete_from_s3)
    end

    it "deletes the files from S3" do
      perform_enqueued_jobs
      expect(file_upload_s3_service_spy).to have_received(:delete_from_s3).with("key1").once
      expect(file_upload_s3_service_spy).to have_received(:delete_from_s3).with("key2").once
    end

    it "destroys the sent submissions updated more than 7 days ago" do
      expect { perform_enqueued_jobs }.to change(Submission, :count).by(-2)
      expect(Submission.exists?(sent_submission_sent_8_days_ago.id)).to be false
      expect(Submission.exists?(sent_submission_sent_7_days_ago.id)).to be false
    end

    it "does not destroy the sent submission updated more recently than 7 days ago" do
      perform_enqueued_jobs
      expect(Submission.exists?(sent_submission_sent_6_days_ago.id)).to be true
    end

    it "does not destroy the submission that hasn't been sent" do
      perform_enqueued_jobs
      expect(Submission.exists?(unsent_submission.id)).to be true
    end

    it "does not destroy the submission that bounced" do
      perform_enqueued_jobs
      expect(Submission.exists?(bounced_submission.id)).to be true
    end

    it "logs deletion" do
      perform_enqueued_jobs
      expect(log_lines).to include(
        hash_including(
          "level" => "INFO",
          "message" => "Form event",
          "event" => "form_submission_deleted",
          "form_id" => form_with_file_upload.id,
          "form_name" => form_with_file_upload.name,
          "submission_reference" => sent_submission_sent_8_days_ago.reference,
          "preview" => "false",
          "job_id" => @job_id,
          "job_class" => "DeleteSubmissionsJob",
        ),
        hash_including(
          "level" => "INFO",
          "message" => "Form event",
          "event" => "form_submission_deleted",
          "form_id" => form_without_file_upload.id,
          "form_name" => form_without_file_upload.name,
          "submission_reference" => sent_submission_sent_7_days_ago.reference,
          "preview" => "false",
          "job_id" => @job_id,
          "job_class" => "DeleteSubmissionsJob",
        ),
      )
    end

    it "sends cloudwatch metric" do
      perform_enqueued_jobs
      expect(CloudWatchService).to have_received(:record_job_started_metric).with("DeleteSubmissionsJob")
    end
  end

  context "when deleting uploaded files fails" do
    before do
      allow(file_upload_s3_service_spy).to receive(:delete_from_s3).and_raise(StandardError, "Test error")
      allow(Sentry).to receive(:capture_exception)
    end

    it "logs at warn level" do
      perform_enqueued_jobs
      expect(log_lines).to include(hash_including(
                                     "level" => "WARN",
                                     "message" => "Error deleting submission - StandardError: Test error",
                                     "form_id" => form_with_file_upload.id,
                                     "submission_reference" => sent_submission_sent_8_days_ago.reference,
                                     "preview" => "false",
                                     "job_id" => @job_id,
                                     "job_class" => "DeleteSubmissionsJob",
                                   ))
    end

    it "sends error to Sentry" do
      perform_enqueued_jobs
      expect(Sentry).to have_received(:capture_exception)
    end

    it "does not destroy the submission that errored" do
      perform_enqueued_jobs
      expect(Submission.exists?(sent_submission_sent_8_days_ago.id)).to be true
    end

    it "continues to delete the next submission" do
      expect { perform_enqueued_jobs }.to change(Submission, :count).by(-1)
      expect(Submission.exists?(sent_submission_sent_7_days_ago.id)).to be false
    end

    it "sends cloudwatch metric" do
      perform_enqueued_jobs
      expect(CloudWatchService).to have_received(:record_job_started_metric).with("DeleteSubmissionsJob")
    end
  end

  def log_lines
    output.string.split("\n").map { |line| JSON.parse(line) }
  end
end
# rubocop:enable RSpec/InstanceVariable
