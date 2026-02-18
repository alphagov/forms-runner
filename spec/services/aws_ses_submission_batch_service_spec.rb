require "rails_helper"

RSpec.describe AwsSesSubmissionBatchService do
  let(:service) { described_class.new(submissions_query:, form:, date:, mode:) }
  let(:form) { build(:form, submission_email:) }
  let(:form_document) { build(:v2_form_document, :with_steps, form_id: form.id) }
  let(:submission_email) { "submit@email.gov.uk" }
  let(:date) { Date.new(2024, 6, 1) }
  let(:mode) { instance_double(Mode, preview?: false) }
  let(:submissions_query) { Submission.all }

  describe "#send_batch" do
    before do
      allow(SubmissionFilenameGenerator).to receive(:batch_csv_filename).and_return("filename.csv")
      allow(CsvGenerator).to receive(:generate_batched_submissions).and_return(%w[csv-content])
      create_list(:submission, 3, form_document:)
    end

    context "when the form does not have a submission email address" do
      let(:submission_email) { nil }

      it "raises an error" do
        expect(AwsSesSubmissionBatchMailer).not_to receive(:batch_submission_email)
        expect { service.send_batch }.to raise_error(StandardError, "Form id: #{form.id} is missing a submission email address")
      end

      context "when the mode is preview" do
        let(:mode) { instance_double(Mode, preview?: true) }

        it "does not send an email" do
          expect(AwsSesSubmissionBatchMailer).not_to receive(:batch_submission_email)
          service.send_batch
        end
      end
    end

    it "calls the SubmissionFilenameGenerator with a nil form version" do
      expect(SubmissionFilenameGenerator).to receive(:batch_csv_filename).with(form_name: form.name, date:, mode:, form_version: nil)
      service.send_batch
    end

    it "returns the message id" do
      message_id = service.send_batch

      last_email = ActionMailer::Base.deliveries.last
      expect(message_id).to eq last_email.message_id
    end

    context "when the csv generator returns multiple csv versions" do
      before do
        allow(CsvGenerator).to receive(:generate_batched_submissions).and_return(%w[csv-content csv-content-2])
        allow(SubmissionFilenameGenerator).to receive(:batch_csv_filename).and_return("filename.csv", "filename-2.csv")
      end

      it "calls the SubmissionFilenameGenerator to generate a filename for each form version" do
        expect(SubmissionFilenameGenerator).to receive(:batch_csv_filename).with(form_name: form.name, date:, mode:, form_version: 1)
        expect(SubmissionFilenameGenerator).to receive(:batch_csv_filename).with(form_name: form.name, date:, mode:, form_version: 2)
        service.send_batch
      end

      it "calls the AwsSesSubmissionBatchMailer to send the email with the generated files" do
        expect(AwsSesSubmissionBatchMailer).to receive(:batch_submission_email)
          .with(
            form:,
            date:,
            mode:,
            files: { "filename.csv" => "csv-content", "filename-2.csv" => "csv-content-2" },
          ).and_call_original

        service.send_batch
      end
    end
  end
end
