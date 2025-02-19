require "rails_helper"

RSpec.describe NotifySubmissionService do
  let(:service) { described_class.new(journey:, form:, notify_email_reference:, mailer_options:) }
  let(:form) do
    build(:form,
          id: 1,
          name: "Form 1",
          submission_email:,
          payment_url:)
  end
  let(:all_steps) { [step] }
  let(:journey) { instance_double(Flow::Journey, completed_steps: all_steps, all_steps:) }
  let(:question) { build :text, question_text: "What is the meaning of life?", text: "42" }
  let(:step) { build :step, question: }
  let(:preview_mode) { false }
  let(:notify_email_reference) { "ffffffff-submission-email" }
  let(:submission_reference) { Faker::Alphanumeric.alphanumeric(number: 8).upcase }
  let(:payment_url) { nil }
  let(:submission_email) { "testing@gov.uk" }
  let(:submission_email_id) { "id-for-submission-email-notification" }
  let(:confirmation_email_id) { "id-for-confirmation-email-notification" }
  let(:timestamp) { Time.zone.now }
  let(:mailer_options) do
    FormSubmissionService::MailerOptions.new(title: form.name,
                                             preview_mode:,
                                             timestamp:,
                                             submission_reference:,
                                             payment_url:)
  end

  let(:output) { StringIO.new }
  let(:logger) do
    ApplicationLogger.new(output).tap do |logger|
      logger.formatter = JsonLogFormatter.new
    end
  end

  before do
    Rails.logger.broadcast_to logger
  end

  after do
    Rails.logger.stop_broadcasting_to logger
  end

  describe "#submit" do
    before do
      allow(CsvGenerator).to receive(:write_submission)
    end

    context "when the submission type is email" do
      before do
        form.submission_type = "email"
      end

      it "calls FormSubmissionMailer" do
        freeze_time do
          allow(FormSubmissionMailer).to receive(:email_confirmation_input).and_call_original

          service.submit

          expect(FormSubmissionMailer).to have_received(:email_confirmation_input).with(
            { text_input: "# What is the meaning of life?\n42\n",
              notify_response_id: notify_email_reference,
              submission_email: "testing@gov.uk",
              mailer_options: instance_of(FormSubmissionService::MailerOptions),
              csv_file: nil },
          ).once
        end
      end

      it "does not write a CSV file" do
        service.submit
        expect(CsvGenerator).not_to have_received(:write_submission)
      end
    end

    context "when the submission type is email_with_csv" do
      before do
        form.submission_type = "email_with_csv"
      end

      it "writes a CSV file" do
        freeze_time do
          service.submit
          expect(CsvGenerator).to have_received(:write_submission)
            .with(all_steps:,
                  submission_reference:,
                  timestamp: Time.zone.now,
                  output_file_path: an_instance_of(String))
        end
      end

      it "calls FormSubmissionMailer passing in a CSV file" do
        freeze_time do
          allow(FormSubmissionMailer).to receive(:email_confirmation_input).and_call_original

          service.submit

          expect(FormSubmissionMailer).to have_received(:email_confirmation_input).with(
            { text_input: "# What is the meaning of life?\n42\n",
              notify_response_id: notify_email_reference,
              submission_email: "testing@gov.uk",
              mailer_options: instance_of(FormSubmissionService::MailerOptions),
              csv_file: instance_of(File) },
          ).once
        end
      end

      context "when Notify returns a bad request response when CSV file is attached" do
        let(:notify_exception) { Notifications::Client::BadRequestError.new(OpenStruct.new(code: 400, body: "Bad file")) }

        before do
          delivery = double

          allow(delivery).to receive(:deliver_now).with(no_args).and_raise(notify_exception)

          allow(FormSubmissionMailer).to receive(:email_confirmation_input).with(hash_including(csv_file: instance_of(File))).and_return delivery
          allow(FormSubmissionMailer).to receive(:email_confirmation_input).with(hash_including(csv_file: nil)).and_call_original

          allow(Sentry).to receive(:capture_exception)
          allow(Rails.logger).to receive(:error)
          allow(LogEventService).to receive(:log_submit).once

          service.submit
        end

        it "tries to send the email again without attaching a file" do
          expect(FormSubmissionMailer).to have_received(:email_confirmation_input).with(
            hash_including(csv_file: instance_of(File)),
          ).once
          expect(FormSubmissionMailer).to have_received(:email_confirmation_input).with(
            hash_including(csv_file: nil),
          ).once
        end

        it "sends the exception to Sentry" do
          expect(Sentry).to have_received(:capture_exception).with(notify_exception)
        end

        it "logs the error" do
          expect(Rails.logger).to have_received(:error).with(
            "Error when attempting to send submission email with CSV attachment, retrying without attachment",
            rescued_exception: ["Notifications::Client::BadRequestError", "Bad file"],
          )
        end
      end
    end

    context "when form being submitted is from previewed form" do
      let(:preview_mode) { true }

      context "when the submission email is set" do
        it "calls FormSubmissionMailer" do
          freeze_time do
            allow(FormSubmissionMailer).to receive(:email_confirmation_input).and_call_original

            service.submit

            expect(FormSubmissionMailer).to have_received(:email_confirmation_input).with(
              { text_input: "# What is the meaning of life?\n42\n",
                notify_response_id: notify_email_reference,
                submission_email: "testing@gov.uk",
                mailer_options: instance_of(FormSubmissionService::MailerOptions),
                csv_file: nil },
            ).once
          end
        end
      end

      context "when the submission email is not set" do
        let(:submission_email) { nil }

        it "does not raise an error" do
          expect { service.submit }.not_to raise_error
        end

        it "does not call FormSubmissionMailer" do
          allow(FormSubmissionMailer).to receive(:email_confirmation_input).and_call_original
          service.submit
          expect(FormSubmissionMailer).not_to have_received(:email_confirmation_input)
        end
      end
    end

    describe "validations" do
      context "when form has no submission email" do
        let(:submission_email) { nil }

        it "raises an error" do
          expect { service.submit }.to raise_error("Form id(1) is missing a submission email address")
        end
      end
    end
  end
end
