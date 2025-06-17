require "rails_helper"

describe FormSubmissionConfirmationMailer, type: :mailer do
  let(:mail) do
    described_class.send_confirmation_email(what_happens_next_markdown:,
                                            support_contact_details:,
                                            notify_response_id: "for-my-ref",
                                            confirmation_email_address:,
                                            mailer_options:)
  end
  let(:mailer_options) do
    FormSubmissionService::MailerOptions.new(title:,
                                             is_preview:,
                                             timestamp: submission_timestamp,
                                             submission_reference:,
                                             payment_url:)
  end
  let(:title) { "Form 1" }
  let(:what_happens_next_markdown) { "Please wait for a response" }
  let(:support_contact_details) { "Call: 0203 222 2222" }
  let(:is_preview) { false }
  let(:confirmation_email_address) { "testing@gov.uk" }
  let(:submission_timestamp) { Time.zone.now }
  let(:submission_reference) { Faker::Alphanumeric.alphanumeric(number: 8).upcase }
  let(:payment_url) { nil }

  context "when form filler wants an form submission confirmation email" do
    before do
      Settings.govuk_notify.form_filler_confirmation_email_template_id = "123456"
      Settings.govuk_notify.form_filler_confirmation_email_welsh_template_id = "7891011"
    end

    context "when the request locale is not set" do
      it "uses the English language template" do
        expect(mail.govuk_notify_template).to eq("123456")
      end
    end

    context "when the request locale is set to :en" do
      include_context "with locale set to :en"

      it "uses the English language template" do
        expect(mail.govuk_notify_template).to eq("123456")
      end
    end

    context "when the request locale is set to :cy" do
      include_context "with locale set to :cy"

      it "uses the Welsh language template" do
        expect(mail.govuk_notify_template).to eq("7891011")
      end
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

    context "when what happens next is missing" do
      let(:what_happens_next_markdown) { nil }

      it "uses placeholder text" do
        expect(mail.govuk_notify_personalisation[:what_happens_next_text]).to eq(I18n.t("mailer.submission_confirmation.default_what_happens_next"))
      end
    end

    context "when what happens next is blank" do
      let(:what_happens_next_markdown) { "" }

      it "uses placeholder text" do
        expect(mail.govuk_notify_personalisation[:what_happens_next_text]).to eq(I18n.t("mailer.submission_confirmation.default_what_happens_next"))
      end
    end

    context "when support contact details are missing" do
      let(:support_contact_details) { nil }

      it "uses placeholder text" do
        expect(mail.govuk_notify_personalisation[:support_contact_details]).to eq(I18n.t("mailer.submission_confirmation.default_support_contact_details"))
      end
    end

    context "when support contact details are blank" do
      let(:support_contact_details) { "" }

      it "uses placeholder text" do
        expect(mail.govuk_notify_personalisation[:support_contact_details]).to eq(I18n.t("mailer.submission_confirmation.default_support_contact_details"))
      end
    end

    it "includes an email reference (mostly used to retrieve specific email in notify for e2e tests)" do
      expect(mail.govuk_notify_reference).to eq("for-my-ref")
    end

    it "does include an email-reply-to" do
      Settings.govuk_notify.form_submission_email_reply_to_id = "send-this-to-me@gov.uk"
      expect(mail.govuk_notify_email_reply_to).to eq("send-this-to-me@gov.uk")
    end

    context "when a payment url is in" do
      let(:payment_url) { "https://www.gov.uk/payments/test-service/pay-for-licence?reference=#{submission_reference}" }

      it "sets the boolean for the payment content to 'yes'" do
        expect(mail.govuk_notify_personalisation[:include_payment_link]).to eq("yes")
      end

      it "sets the payment_link" do
        expect(mail.govuk_notify_personalisation[:payment_link]).to eq(payment_url)
      end
    end

    context "when a payment link is not set" do
      let(:payment_url) { nil }

      it "sets the boolean for the payment content to 'no'" do
        expect(mail.govuk_notify_personalisation[:include_payment_link]).to eq("no")
      end

      it "sets the payment link personalisation to an empty string" do
        expect(mail.govuk_notify_personalisation[:payment_link]).to eq("")
      end
    end

    describe "submission date/time" do
      context "with a time in BST" do
        let(:timestamp) { Time.utc(2022, 9, 14, 8, 0o0, 0o0) }

        it "includes the time user submitted the form" do
          travel_to timestamp do
            expect(mail.govuk_notify_personalisation[:submission_time]).to eq("9:00am")
          end
        end

        context "when the request locale is not set" do
          it "includes the date user submitted the form in English" do
            travel_to timestamp do
              expect(mail.govuk_notify_personalisation[:submission_date]).to eq("14 September 2022")
            end
          end
        end

        context "when the request locale is set to :en" do
          include_context "with locale set to :en"
          it "includes the date user submitted the form in English" do
            travel_to timestamp do
              expect(mail.govuk_notify_personalisation[:submission_date]).to eq("14 September 2022")
            end
          end
        end

        context "when the request locale is set to :cy" do
          include_context "with locale set to :cy"

          it "includes the date user submitted the form in Welsh" do
            travel_to timestamp do
              expect(mail.govuk_notify_personalisation[:submission_date]).to eq("14 Medi 2022")
            end
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
      let(:is_preview) { true }

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
