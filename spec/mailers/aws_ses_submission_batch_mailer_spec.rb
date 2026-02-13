require "rails_helper"

describe AwsSesSubmissionBatchMailer, type: :mailer do
  subject(:mail) { described_class.batch_submission_email(form:, date:, mode:, files:) }

  let(:form) { build(:form, submission_email: submission_email_address) }
  let(:submission_email_address) { "submission@email.gov.uk" }
  let(:date) { Date.new(2024, 6, 1) }
  let(:mode) { instance_double(Mode, preview?: false) }

  let(:files) { { "filename.csv" => "csv-content", "filename-2.csv" => "csv-content-2" } }

  context "when form filler submits a completed form" do
    it "sends an email to the form's submission email address" do
      expect(mail.to).to eq([submission_email_address])
    end

    describe "subject" do
      context "when the mode is preview" do
        let(:mode) { instance_double(Mode, preview?: true) }

        it "sets the subject for a preview" do
          expect(mail.subject).to eq(I18n.t("mailer.submission_batch.subject_preview", form_name: form.name, date: "1 June 2024"))
        end
      end

      context "when the mode is not preview" do
        let(:mode) { instance_double(Mode, preview?: false) }

        it "sets the subject" do
          expect(mail.subject).to eq(I18n.t("mailer.submission_batch.subject", form_name: form.name, date: "1 June 2024"))
        end
      end
    end

    it "has the files attached with expected filenames" do
      expect(mail.attachments[0].filename).to eq("filename.csv")
      expect(mail.attachments[1].filename).to eq("filename-2.csv")
    end

    it "has the files attached with expected content" do
      expect(mail.attachments[0].body.to_s).to eq("csv-content")
      expect(mail.attachments[1].body.to_s).to eq("csv-content-2")
    end
  end
end
