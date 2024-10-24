require "rails_helper"

RSpec.describe FormSubmissionService do
  let(:service) { described_class.call(current_context:, email_confirmation_input:, preview_mode:) }
  let(:form) do
    build(:form,
          id: 1,
          name: "Form 1",
          what_happens_next_markdown:,
          support_email:,
          support_phone:,
          support_url:,
          support_url_text:,
          submission_email:,
          payment_url:,
          submission_type:)
  end
  let(:submission_type) { "email" }
  let(:what_happens_next_markdown) { "We usually respond to applications within 10 working days." }
  let(:support_email) { Faker::Internet.email(domain: "example.gov.uk") }
  let(:support_phone) { Faker::Lorem.paragraph(sentence_count: 2, supplemental: true, random_sentences_to_add: 4) }
  let(:support_url) { Faker::Internet.url(host: "gov.uk") }
  let(:support_url_text) { Faker::Lorem.sentence(word_count: 1, random_words_to_add: 4) }
  let(:current_context) { OpenStruct.new(form:, completed_steps: [step], support_details: OpenStruct.new(call_back_url: "http://gov.uk")) }
  let(:request) { OpenStruct.new({ url: "url", method: "method" }) }
  let(:step) { OpenStruct.new({ question_text: "What is the meaning of life?", show_answer_in_email: "42" }) }
  let(:preview_mode) { false }
  let(:email_confirmation_input) { build :email_confirmation_input_opted_in }
  let(:reference) { Faker::Alphanumeric.alphanumeric(number: 8).upcase }
  let(:payment_url) { nil }
  let(:submission_email) { "testing@gov.uk" }
  let(:submission_email_id) { "id-for-submission-email-notification" }
  let(:confirmation_email_id) { "id-for-confirmation-email-notification" }

  let(:output) { StringIO.new }
  let(:logger) do
    ApplicationLogger.new(output).tap do |logger|
      logger.formatter = JsonLogFormatter.new
    end
  end

  before do
    Rails.logger.broadcast_to logger

    allow(ReferenceNumberService).to receive(:generate).and_return(reference)
  end

  after do
    Rails.logger.stop_broadcasting_to logger
  end

  describe "#submit" do
    let(:notify_submission_service_spy) { instance_double(NotifySubmissionService) }

    before do
      allow(NotifySubmissionService).to receive(:new).and_return(notify_submission_service_spy)
      allow(notify_submission_service_spy).to receive(:submit)
    end

    it "returns the submission reference" do
      expect(service.submit).to eq reference
    end

    it "includes the submission reference in the logging context" do
      service.submit
      expect(log_lines[0]["submission_reference"]).to eq(reference)
    end

    shared_examples "logging" do
      it "logs submission" do
        allow(LogEventService).to receive(:log_submit).once

        service.submit

        expect(LogEventService).to have_received(:log_submit).with(
          current_context,
          requested_email_confirmation: true,
          preview: preview_mode,
          submission_type:,
        )
      end
    end

    describe "submitting the form to the processing team" do
      context "when the submission type is email" do
        let(:submission_type) { "email" }

        it "calls NotifySubmissionService to submit the form" do
          service.submit
          expect(notify_submission_service_spy).to have_received(:submit)
        end
      end

      context "when the submission type is email_with_csv" do
        let(:submission_type) { "email_with_csv" }

        it "calls NotifySubmissionService to submit the form" do
          service.submit
          expect(notify_submission_service_spy).to have_received(:submit)
        end

        include_examples "logging"
      end

      context "when the submission type is s3" do
        let(:submission_type) { "s3" }
        let(:s3_submission_service_spy) { instance_double(S3SubmissionService) }

        before do
          allow(S3SubmissionService).to receive(:new).and_return(s3_submission_service_spy)
          allow(s3_submission_service_spy).to receive("submit")
        end

        it "creates a S3SubmissionService instance" do
          freeze_time do
            service.submit

            expect(S3SubmissionService).to have_received(:new).with(
              current_context:,
              timestamp: Time.zone.now,
              submission_reference: reference,
            ).once
          end
        end

        it "calls upload_submission_csv_to_s3" do
          service.submit
          expect(s3_submission_service_spy).to have_received(:submit)
        end

        it "does not call NotifySubmissionService to submit the form" do
          service.submit
          expect(notify_submission_service_spy).not_to have_received(:submit)
        end

        include_examples "logging"
      end

      context "when form being submitted is from previewed form" do
        let(:preview_mode) { true }

        include_examples "logging"
      end

      describe "validations" do
        context "when current context has no completed steps (i.e questions/answers)" do
          let(:current_context) { OpenStruct.new(form:, steps: []) }
          let(:result) { service.submit }

          it "raises an error" do
            expect { result }.to raise_error("Form id(1) has no completed steps i.e questions/answers to submit")
          end
        end
      end
    end

    describe "sending the confirmation email to the user" do
      it "calls FormSubmissionConfirmationMailer" do
        freeze_time do
          allow(FormSubmissionConfirmationMailer).to receive(:send_confirmation_email).and_call_original
          service.submit
          expect(FormSubmissionConfirmationMailer).to have_received(:send_confirmation_email).with(
            { what_happens_next_markdown: form.what_happens_next_markdown,
              support_contact_details: contact_support_details_format,
              notify_response_id: email_confirmation_input.confirmation_email_reference,
              confirmation_email_address: email_confirmation_input.confirmation_email_address,
              mailer_options: instance_of(FormSubmissionService::MailerOptions) },
          ).once
        end
      end

      context "when user does not want a confirmation email" do
        let(:email_confirmation_input) { build :email_confirmation_input }

        it "does not call FormSubmissionConfirmationMailer" do
          allow(FormSubmissionConfirmationMailer).to receive(:send_confirmation_email)
          service.submit
          expect(FormSubmissionConfirmationMailer).not_to have_received(:send_confirmation_email)
        end
      end

      context "when form is draft" do
        context "when form does not have 'what happens next details'" do
          let(:what_happens_next_markdown) { nil }

          it "does not call FormSubmissionConfirmationMailer" do
            allow(FormSubmissionConfirmationMailer).to receive(:send_confirmation_email)
            service.submit
            expect(FormSubmissionConfirmationMailer).not_to have_received(:send_confirmation_email)
          end
        end

        context "when form does not have any support details" do
          let(:support_email) { nil }
          let(:support_phone) { nil }
          let(:support_url) { nil }
          let(:support_url_text) { nil }

          it "does not call FormSubmissionConfirmationMailer" do
            allow(FormSubmissionConfirmationMailer).to receive(:send_confirmation_email)
            service.submit
            expect(FormSubmissionConfirmationMailer).not_to have_received(:send_confirmation_email)
          end
        end
      end
    end
  end

  def contact_support_details_format
    phone_number = "#{form.support_phone}\n\n[#{I18n.t('support_details.call_charges')}](http://gov.uk)"
    email = "[#{form.support_email}](mailto:#{form.support_email})"
    online = "[#{form.support_url_text}](#{form.support_url})"
    [phone_number, email, online].compact_blank.join("\n\n")
  end

  def log_lines
    output.string.split("\n").map { |line| JSON.parse(line) }
  end
end
