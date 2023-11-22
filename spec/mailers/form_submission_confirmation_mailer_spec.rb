require "rails_helper"

describe FormSubmissionConfirmationMailer, type: :mailer do
  let(:mail) do
    described_class.send_confirmation_email(title:,
                                            what_happens_next_text:,
                                            support_contact_details:,
                                            submission_timestamp:,
                                            preview_mode:,
                                            reference: "for-my-ref",
                                            confirmation_email_address:)
  end
  let(:title) { "Form 1" }
  let(:what_happens_next_text) { "Please wait for a response" }
  let(:support_contact_details) { "Call: 0203 222 2222" }
  let(:preview_mode) { false }
  let(:confirmation_email_address) { "testing@gov.uk" }
  let(:submission_timestamp) { Time.zone.now }

  context "when form filler wants an form submission confirmation email" do
    it "sends an email with the correct template" do
      Settings.govuk_notify.form_filler_confirmation_email_template_id = "123456"
      expect(mail.govuk_notify_template).to eq("123456")
    end

    it "sends an email to the form filler's email address" do
      expect(mail.to).to eq(["testing@gov.uk"])
    end

    it "includes the form title" do
      expect(mail.govuk_notify_personalisation[:title]).to eq("Form 1")
    end

    it "includes the forms what happens next" do
      expect(mail.govuk_notify_personalisation[:what_happens_next_text]).to eq("Please wait for a response")
    end

    it "includes the forms support contact details" do
      expect(mail.govuk_notify_personalisation[:support_contact_details]).to eq("Call: 0203 222 2222")
    end

    it "includes an email reference (mostly used to retrieve specific email in notify for e2e tests)" do
      expect(mail.govuk_notify_reference).to eq("for-my-ref")
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
