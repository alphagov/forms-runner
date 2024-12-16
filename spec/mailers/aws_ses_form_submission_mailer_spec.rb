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

  context "when a file to attach is included in the arguments" do
    let(:test_file) { Tempfile.new("csv") }
    let(:filename) { "a-file.csv" }
    let(:files) { { filename => test_file } }

    after do
      test_file.unlink
    end

    it "adds the file as an attachment" do
      expect(mail.attachments.size).to eq(1)
    end

    it "uses the filename for the attachment" do
      expect(mail.attachments.first.filename).to eq(filename)
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
