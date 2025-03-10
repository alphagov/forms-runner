require "rails_helper"

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
      "1" => { uploaded_file_key: "key1" },
      "2" => { uploaded_file_key: "key2" },
    }
  end

  let!(:sent_submission_updated_8_days_ago) do
    create :submission,
           :sent,
           reference: "SENT8DAYS",
           form_id: form_with_file_upload.id,
           form_document: form_with_file_upload,
           updated_at: 8.days.ago,
           answers: form_with_file_upload_answers
  end
  let!(:sent_submission_updated_7_days_ago) do
    create :submission,
           :sent,
           reference: "SENT7DAYS",
           form_id: form_without_file_upload.id,
           form_document: form_without_file_upload,
           updated_at: 7.days.ago
  end
  let!(:sent_submission_updated_6_days_ago) do
    create :submission,
           :sent,
           reference: "SENT6DAYS",
           form_id: form_without_file_upload.id,
           form_document: form_without_file_upload,
           updated_at: 6.days.ago
  end
  let!(:unsent_submission) { create :submission, reference: "UNSENT", updated_at: 7.days.ago }

  before do
    allow(Question::FileUploadS3Service).to receive(:new).and_return(file_upload_s3_service_spy)

    described_class.perform_later
  end

  context "when deleting uploaded files is successful" do
    before do
      allow(file_upload_s3_service_spy).to receive(:delete_from_s3)
      allow(EventLogger).to receive(:log_form_event)
    end

    it "deletes the files from S3" do
      perform_enqueued_jobs
      expect(file_upload_s3_service_spy).to have_received(:delete_from_s3).with("key1").once
      expect(file_upload_s3_service_spy).to have_received(:delete_from_s3).with("key2").once
    end

    it "destroys the sent submissions updated more than 7 days ago" do
      expect { perform_enqueued_jobs }.to change(Submission, :count).by(-2)
      expect(Submission.exists?(sent_submission_updated_8_days_ago.id)).to be false
      expect(Submission.exists?(sent_submission_updated_7_days_ago.id)).to be false
    end

    it "does not destroy the sent submission updated more recently than 7 days ago" do
      perform_enqueued_jobs
      expect(Submission.exists?(sent_submission_updated_6_days_ago.id)).to be true
    end

    it "does not destroy the submission that hasn't been sent" do
      perform_enqueued_jobs
      expect(Submission.exists?(unsent_submission.id)).to be true
    end

    it "logs deletion" do
      perform_enqueued_jobs
      expect(EventLogger).to have_received(:log_form_event).once.with("submission_deleted", {
        submission_reference: "SENT8DAYS", form_id: form_with_file_upload.id, form_name: form_with_file_upload.name, job_id: anything
      })
      expect(EventLogger).to have_received(:log_form_event).once.with("submission_deleted", {
        submission_reference: "SENT7DAYS", form_id: form_without_file_upload.id, form_name: form_without_file_upload.name, job_id: anything
      })
    end
  end

  context "when deleting uploaded files fails" do
    before do
      allow(file_upload_s3_service_spy).to receive(:delete_from_s3).and_raise(StandardError, "Test error")
      allow(Rails.logger).to receive(:warn).at_least(:once)
      allow(Sentry).to receive(:capture_exception)
    end

    it "logs at warn level" do
      perform_enqueued_jobs
      expect(Rails.logger).to have_received(:warn).with("Error deleting submission - StandardError: Test error", {
        form_id: form_with_file_upload.id,
        submission_reference: sent_submission_updated_8_days_ago.reference,
        job_id: anything,
      })
    end

    it "sends error to Sentry" do
      perform_enqueued_jobs
      expect(Sentry).to have_received(:capture_exception)
    end

    it "does not destroy the submission that errored" do
      perform_enqueued_jobs
      expect(Submission.exists?(sent_submission_updated_8_days_ago.id)).to be true
    end

    it "continues to delete the next submission" do
      expect { perform_enqueued_jobs }.to change(Submission, :count).by(-1)
      expect(Submission.exists?(sent_submission_updated_7_days_ago.id)).to be false
    end
  end
end
