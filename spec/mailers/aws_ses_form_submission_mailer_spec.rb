require "rails_helper"

describe AwsSesFormSubmissionMailer, type: :mailer do
  let(:mail) { described_class.submission_email(answer_content:, submission_email_address:, mailer_options:, files:) }
  let(:title) { "Form 1" }
  let(:answer_content) { "My question: My answer" }
  let(:preview_mode) { false }
  let(:submission_email_address) { "testing@gov.uk" }
  let(:files) { {} }
  let(:submission_reference) { Faker::Alphanumeric.alphanumeric(number: 8).upcase }
  let(:payment_url) { nil }
  let(:mailer_options) do
    FormSubmissionService::MailerOptions.new(title:,
                                             preview_mode:,
                                             timestamp: submission_timestamp,
                                             submission_reference:,
                                             payment_url:)
  end

  context "when form filler submits a completed form" do
    it "sends an email to the form's submission email address" do
      expect(mail.to).to eq([submission_email_address])
    end

    it "sets the subject" do
      expect(mail.subject).to eq("Form submission: #{title} - reference: #{submission_reference}")
    end

    it "includes the answers" do
      expect(mail.body).to match(answer_content)
    end

    it "includes the submission reference" do
      expect(mail.body).to match("reference number: #{submission_reference}")
    end

    it "includes text about checking the answers" do
      expect(mail.body).to have_css("p", text: I18n.t("mailer.submission.check_before_using"))
    end

    it "includes the warning about not replying" do
      expect(mail.body).to have_css("h2", text: I18n.t("mailer.submission.cannot_reply.heading"))
      expect(mail.body).to include(I18n.t("mailer.submission.cannot_reply.contact_form_filler"))
      expect(mail.body).to include(I18n.t("mailer.submission.cannot_reply.contact_forms_team"))
    end

    describe "submission date/time" do
      context "with a time in BST" do
        let(:timestamp) { Time.utc(2022, 9, 14, 8, 0o0, 0o0) }

        it "includes the date and time the user submitted the form" do
          travel_to timestamp do
            expect(mail.body).to match("This form was submitted at 9:00am on 14 September 2022")
          end
        end
      end

      context "with a time in GMT" do
        let(:timestamp) { Time.utc(2022, 12, 14, 13, 0o0, 0o0) }

        it "includes the date and time the user submitted the form" do
          travel_to timestamp do
            expect(mail.body).to match("This form was submitted at 1:00pm on 14 December 2022")
          end
        end
      end
    end
  end

  context "when files to attach are included in the arguments" do
    let(:csv_file_name) { "first-file.csv" }
    let(:png_file_name) { "second-file.png" }
    let(:files) do
      {
        csv_file_name => Faker::Lorem.sentence,
        png_file_name => Faker::Lorem.sentence,
      }
    end

    it "has 2 attachments" do
      expect(mail.attachments.size).to eq(2)
    end

    it "has the files attached with expected filenames" do
      expect(mail.attachments[0].filename).to eq(csv_file_name)
      expect(mail.attachments[1].filename).to eq(png_file_name)
    end

    it "has the files attached with expected content" do
      expect(mail.attachments[0].body).to eq(files[csv_file_name])
      expect(mail.attachments[1].body).to eq(files[png_file_name])
    end
  end

private

  def submission_timezone
    Rails.configuration.x.submission.time_zone || "UTC"
  end

  def submission_timestamp
    Time.use_zone(submission_timezone) { Time.zone.now }
  end
end
