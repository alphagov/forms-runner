require "rails_helper"

describe AwsSesSubmissionBatchMailer, type: :mailer do
  subject(:mail) { described_class.batch_submission_email(form:, date:, mode:, files:) }

  let(:form) { build(:form, submission_email: submission_email_address) }
  let(:submission_email_address) { "submission@email.gov.uk" }
  let(:date) { Date.new(2024, 6, 1) }
  let(:mode) { Mode.new("form") }
  let(:files) { { "filename.csv" => "csv-content", "filename-2.csv" => "csv-content-2" } }

  let(:expected_date_string) { "1 June 2024" }

  context "when form filler submits a completed form" do
    it "sends an email to the form's submission email address" do
      expect(mail.to).to eq([submission_email_address])
    end

    describe "subject" do
      context "when the mode is preview" do
        let(:mode) { Mode.new("preview-live") }

        it "sets the subject for a preview" do
          expect(mail.subject).to eq(I18n.t("mailer.submission_batch.subject_preview", form_name: form.name, date: expected_date_string))
        end
      end

      context "when the mode is not preview" do
        it "sets the subject" do
          expect(mail.subject).to eq(I18n.t("mailer.submission_batch.subject", form_name: form.name, date: expected_date_string))
        end
      end
    end

    describe "attachments" do
      it "has the files attached with expected filenames" do
        expect(mail.attachments[0].filename).to eq("filename.csv")
        expect(mail.attachments[1].filename).to eq("filename-2.csv")
      end

      it "has the files attached with expected content" do
        expect(mail.attachments[0].body.to_s).to eq("csv-content")
        expect(mail.attachments[1].body.to_s).to eq("csv-content-2")
      end
    end

    describe "the html part" do
      let(:part) { mail.html_part }

      it "has the email subject as its title" do
        expect(part.body).to have_title(mail.subject)
      end

      it "has a link to GOV.UK" do
        expect(part.body).to have_link("GOV.UK", href: "https://www.gov.uk")
      end

      it "includes the form name" do
        expect(part.body).to have_css("p", text: I18n.t("mailer.form_name", form_name: form.name))
      end

      it "does not include the form preview text" do
        expect(part.body).not_to include("These are test submissions")
      end

      [
        %w[preview-live live],
        %w[preview-draft draft],
        %w[preview-archived archived],
      ].each do |mode_string, tag|
        context "when the mode is #{mode_string}" do
          let(:mode) { Mode.new(mode_string) }

          it "includes the preview text for #{tag}" do
            expect(part.body).to have_css("p", text: I18n.t("mailer.submission_batch.preview", tag: tag))
          end
        end
      end

      context "when there is a single attachment" do
        let(:files) { { "filename.csv" => "csv-content" } }

        it "includes the explainer text for a single attachment" do
          expect(part.body).to have_css("p", text: I18n.t("mailer.submission_batch.single_file_explainer", date: expected_date_string))
        end

        it "lists the filename of the attachment" do
          expect(part.body).to have_css("ul", text: "filename.csv")
        end
      end

      context "when there are multiple attachments" do
        let(:files) { { "filename.csv" => "csv-content", "filename-2.csv" => "csv-content-2" } }

        it "includes the explainer text for multiple attachments" do
          expect(part.body).to have_css("p", text: I18n.t("mailer.submission_batch.multiple_files_explainer", date: expected_date_string))
        end

        it "lists the filenames of the attachments" do
          expect(part.body).to have_css("ul", text: "filename.csv")
          expect(part.body).to have_css("ul", text: "filename-2.csv")
        end
      end
    end

    describe "the plaintext part" do
      let(:part) { mail.text_part }

      it "includes the form name" do
        expect(part.body).to have_text(I18n.t("mailer.form_name", form_name: form.name))
      end

      it "does not include the form preview text" do
        expect(part.body).not_to include("These are test submissions")
      end

      [
        %w[preview-live live],
        %w[preview-draft draft],
        %w[preview-archived archived],
      ].each do |mode_string, tag|
        context "when the mode is #{mode_string}" do
          let(:mode) { Mode.new(mode_string) }

          it "includes the preview text for #{tag}" do
            expect(part.body).to have_text(I18n.t("mailer.submission_batch.preview", tag: tag))
          end
        end
      end

      context "when there is a single attachment" do
        let(:files) { { "filename.csv" => "csv-content" } }

        it "includes the explainer text for a single attachment" do
          expect(part.body).to have_text(I18n.t("mailer.submission_batch.single_file_explainer", date: expected_date_string))
        end

        it "lists the filename of the attachment" do
          expect(part.body).to have_text("  • filename.csv")
        end
      end

      context "when there are multiple attachments" do
        let(:files) { { "filename.csv" => "csv-content", "filename-2.csv" => "csv-content-2" } }

        it "includes the explainer text for multiple attachments" do
          expect(part.body).to have_text(I18n.t("mailer.submission_batch.multiple_files_explainer", date: expected_date_string))
        end

        it "lists the filenames of the attachments" do
          expect(part.body).to have_text("  • filename.csv")
          expect(part.body).to have_text("  • filename-2.csv")
        end
      end
    end
  end
end
