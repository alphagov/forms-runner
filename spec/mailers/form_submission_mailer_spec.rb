require "rails_helper"

describe FormSubmissionMailer, type: :mailer do
  let(:mail) { described_class.email_confirmation_input(text_input:, notify_response_id: "for-my-ref", submission_email:, mailer_options:) }
  let(:title) { "Form 1" }
  let(:text_input) { "My question: My answer" }
  let(:preview_mode) { false }
  let(:submission_email) { "testing@gov.uk" }
  let(:submission_timestamp) { Time.zone.now }
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
    it "sends an email with the correct template" do
      Settings.govuk_notify.form_submission_email_template_id = "123456"
      expect(mail.govuk_notify_template).to eq("123456")
    end

    it "sends an email to the form's submission email address" do
      expect(mail.to).to eq(["testing@gov.uk"])
    end

    it "includes the form title" do
      expect(mail.govuk_notify_personalisation[:title]).to eq("Form 1")
    end

    it "includes the form question and answers from the user" do
      expect(mail.govuk_notify_personalisation[:text_input]).to eq("My question: My answer")
    end

    it "includes the an email reference (mostly used to retrieve specific email in notify for e2e tests)" do
      expect(mail.govuk_notify_reference).to eq("for-my-ref")
    end

    it "does not use the preview personalisation" do
      expect(mail.govuk_notify_personalisation[:test]).to eq("no")
      expect(mail.govuk_notify_personalisation[:not_test]).to eq("yes")
    end

    context "when a payment url is in" do
      let(:payment_url) { "https://www.gov.uk/payments/test-service/pay-for-licence?reference=#{submission_reference}" }

      it "sets the boolean for the payment content to 'yes'" do
        expect(mail.govuk_notify_personalisation[:include_payment_link]).to eq("yes")
      end
    end

    context "when a payment link is not set" do
      let(:payment_url) { nil }

      it "sets the boolean for the payment content to 'no'" do
        expect(mail.govuk_notify_personalisation[:include_payment_link]).to eq("no")
      end
    end

    it "does include an email-reply-to" do
      Settings.govuk_notify.form_submission_email_reply_to_id = "send-this-to-me@gov.uk"
      expect(mail.govuk_notify_email_reply_to).to eq("send-this-to-me@gov.uk")
    end

    describe "submission date/time" do
      context "with a time in BST" do
        let(:timestamp) { Time.utc(2022, 9, 14, 8, 0o0, 0o0) }

        it "includes the time user submitted the form" do
          travel_to timestamp do
            expect(mail.govuk_notify_personalisation[:submission_time]).to eq("9:00am")
          end
        end

        it "includes the date user submitted the form" do
          travel_to timestamp do
            expect(mail.govuk_notify_personalisation[:submission_date]).to eq("14 September 2022")
          end
        end
      end

      context "with a time in GMT" do
        let(:timestamp) { Time.utc(2022, 12, 14, 13, 0o0, 0o0) }

        it "includes the time user submitted the form" do
          travel_to timestamp do
            expect(mail.govuk_notify_personalisation[:submission_time]).to eq("1:00pm")
          end
        end

        it "includes the date user submitted the form" do
          travel_to timestamp do
            expect(mail.govuk_notify_personalisation[:submission_date]).to eq("14 December 2022")
          end
        end
      end
    end

    context "when the submission is from preview mode" do
      let(:preview_mode) { true }

      it "uses the preview personalisation" do
        expect(mail.govuk_notify_personalisation[:test]).to eq("yes")
        expect(mail.govuk_notify_personalisation[:not_test]).to eq("no")
      end
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
