require "rails_helper"

RSpec.describe FormSubmissionService do
  include ActiveJob::TestHelper

  subject(:service) { described_class.call(current_context:, email_confirmation_input:, mode:) }

  let(:mode) { Mode.new }
  let(:email_confirmation_input) { build :email_confirmation_input_opted_in }

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
          submission_type:,
          pages:,
          document_json: form_document)
  end
  let(:form_document) { build(:v2_form_document).to_h.with_indifferent_access }
  let(:pages) { [build(:page, id: 2, answer_type: "text")] }
  let(:submission_type) { "email" }
  let(:what_happens_next_markdown) { "We usually respond to applications within 10 working days." }
  let(:support_email) { Faker::Internet.email(domain: "example.gov.uk") }
  let(:support_phone) { Faker::Lorem.paragraph(sentence_count: 2, supplemental: true, random_sentences_to_add: 4) }
  let(:support_url) { Faker::Internet.url(host: "gov.uk") }
  let(:support_url_text) { Faker::Lorem.sentence(word_count: 1, random_words_to_add: 4) }
  let(:payment_url) { nil }
  let(:submission_email) { "testing@gov.uk" }

  let(:reference) { Faker::Alphanumeric.alphanumeric(number: 8).upcase }

  let(:step) { OpenStruct.new({ question_text: "What is the meaning of life?", show_answer_in_email: "42" }) }
  let(:all_steps) { [step] }
  let(:journey) { instance_double(Flow::Journey, completed_steps: all_steps, all_steps:) }
  let(:answers) do
    {
      "1" => {
        selection: "Option 1",
      },
      "2" => {
        text: "Example text",
      },
    }
  end
  let(:current_context) { instance_double(Flow::Context, form:, journey:, completed_steps: all_steps, support_details: OpenStruct.new(call_charges_url: "http://gov.uk"), answers:) }

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
          preview: mode.preview?,
          submission_type:,
        )
      end
    end

    describe "submitting the form to the processing team" do
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
              journey:,
              form:,
              timestamp: Time.zone.now,
              submission_reference: reference,
              is_preview: mode.preview?,
            ).once
          end
        end

        it "calls upload_submission_csv_to_s3" do
          service.submit
          expect(s3_submission_service_spy).to have_received(:submit)
        end

        include_examples "logging"
      end

      shared_examples "submits via AWS SES" do
        let(:aws_ses_submission_service_spy) { instance_double(AwsSesSubmissionService) }
        let(:mail_message_id) { "1234" }

        let(:req_headers) do
          {
            "X-API-Token" => Settings.forms_api.auth_key,
            "Accept" => "application/json",
          }
        end

        before do
          ActiveResource::HttpMock.respond_to do |mock|
            mock.get "/api/v2/forms/1/live", req_headers, form.to_json, 200
          end

          allow(Flow::Journey).to receive(:new)

          allow(AwsSesSubmissionService).to receive(:new).and_return(aws_ses_submission_service_spy)
          allow(aws_ses_submission_service_spy).to receive(:submit).and_return(mail_message_id)
        end

        it "enqueues a job to send the submission" do
          assert_enqueued_with(job: SendSubmissionJob) do
            service.submit
          end

          expect(aws_ses_submission_service_spy).not_to have_received(:submit)

          perform_enqueued_jobs

          expect(aws_ses_submission_service_spy).to have_received(:submit)
        end

        it "saves the submission data" do
          expect {
            service.submit
          }.to change(Submission, :count).by(1)

          expect(Submission.last).to have_attributes(reference:, form_id: form.id, answers: answers.deep_stringify_keys,
                                                     mode: "form", mail_message_id: nil, form_document: form_document,
                                                     sent_at: nil)
        end

        context "when the job fails to enqueue" do
          let(:enqueue_error) { nil }

          define_negated_matcher :not_change, :change

          before do
            allow(SendSubmissionJob).to receive(:perform_later).and_yield(instance_double(SendSubmissionJob, successfully_enqueued?: false, enqueue_error:))
          end

          context "and there is no enqueue error" do
            it "raises an error" do
              expect { service.submit }.to not_change(Submission, :count).and raise_error(StandardError, "Failed to enqueue submission for reference #{reference}")
            end
          end

          context "and there is an enqueue error" do
            let(:enqueue_error) { ActiveJob::EnqueueError.new("An error occurred enqueueing job") }

            it "raises an error" do
              expect { service.submit }.to not_change(Submission, :count).and raise_error(StandardError, "Failed to enqueue submission for reference #{reference}: An error occurred enqueueing job")
            end
          end
        end
      end

      context "when the submission type is email" do
        let(:submission_type) { "email" }

        include_examples "submits via AWS SES"

        include_examples "logging"
      end

      context "when the submission type is email_with_csv" do
        let(:submission_type) { "email_with_csv" }

        include_examples "submits via AWS SES"

        include_examples "logging"
      end

      context "when form being submitted is from previewed form" do
        let(:mode) { Mode.new("preview-live") }

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
