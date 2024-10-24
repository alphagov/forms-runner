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
          payment_url:)
  end
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
    let(:csv_submission_service_spy) { instance_double(CsvSubmissionService) }

    before do
      allow(CsvSubmissionService).to receive(:new).and_return csv_submission_service_spy
      allow(csv_submission_service_spy).to receive(:write)
    end

    it "returns the submission reference" do
      expect(service.submit).to eq reference
    end

    it "includes the submission reference in the logging context" do
      service.submit
      expect(log_lines[0]["submission_reference"]).to eq(reference)
    end

    describe "submitting the form to the processing team" do
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
                notify_response_id: email_confirmation_input.submission_email_reference,
                submission_email: "testing@gov.uk",
                mailer_options: instance_of(FormSubmissionService::MailerOptions),
                csv_file: nil },
            ).once
          end
        end

        it "does not write a CSV file" do
          service.submit
          expect(csv_submission_service_spy).not_to have_received(:write)
        end

        it "logs submission" do
          allow(LogEventService).to receive(:log_submit).once

          service.submit

          expect(LogEventService).to have_received(:log_submit).with(
            current_context,
            requested_email_confirmation: true,
            preview: false,
            csv_attached: false,
          )
        end
      end

      context "when the submission type is email_with_csv" do
        before do
          form.submission_type = "email_with_csv"
        end

        it "writes a CSV file" do
          service.submit
          expect(csv_submission_service_spy).to have_received(:write)
        end

        it "calls FormSubmissionMailer passing in a CSV file" do
          freeze_time do
            allow(FormSubmissionMailer).to receive(:email_confirmation_input).and_call_original

            service.submit

            expect(FormSubmissionMailer).to have_received(:email_confirmation_input).with(
              { text_input: "# What is the meaning of life?\n42\n",
                notify_response_id: email_confirmation_input.submission_email_reference,
                submission_email: "testing@gov.uk",
                mailer_options: instance_of(FormSubmissionService::MailerOptions),
                csv_file: instance_of(File) },
            ).once
          end
        end

        it "logs submission with csv_attached=true" do
          allow(LogEventService).to receive(:log_submit).once

          service.submit

          expect(LogEventService).to have_received(:log_submit).with(
            current_context,
            requested_email_confirmation: true,
            preview: false,
            csv_attached: true,
          )
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

          it "logs submission with csv_attached: false" do
            expect(LogEventService).to have_received(:log_submit).with(
              current_context,
              requested_email_confirmation: true,
              preview: false,
              csv_attached: false,
            )
          end
        end
      end

      context "when the submission type is s3" do
        let(:s3_submission_service_spy) { instance_double(S3SubmissionService) }

        before do
          form.submission_type = "s3"
          form.s3_bucket_name = "a-bucket"
          form.s3_bucket_aws_account_id = "123456789"
          form.s3_bucket_region = "eu-west-1"
          form.submission_email = nil

          allow(S3SubmissionService).to receive(:new).and_return(s3_submission_service_spy)
          allow(s3_submission_service_spy).to receive("upload_file_to_s3")
        end

        it "writes a CSV file" do
          service.submit
          expect(csv_submission_service_spy).to have_received(:write)
        end

        it "creates a S3SubmissionService instance passing in a CSV file" do
          freeze_time do
            service.submit

            expect(S3SubmissionService).to have_received(:new).with(
              file_path: an_instance_of(String),
              form_id: form.id,
              s3_bucket_name: form.s3_bucket_name,
              s3_bucket_aws_account_id: form.s3_bucket_aws_account_id,
              s3_bucket_region: form.s3_bucket_region,
              timestamp: Time.zone.now,
              submission_reference: reference,
            ).once
          end
        end

        it "calls upload_file_to_s3" do
          service.submit
          expect(s3_submission_service_spy).to have_received(:upload_file_to_s3)
        end
      end

      describe "validations" do
        context "when form has no submission email" do
          let(:submission_email) { nil }

          it "raises an error" do
            expect { service.submit }.to raise_error("Form id(1) is missing a submission email address")
          end
        end

        context "when current context has no completed steps (i.e questions/answers)" do
          let(:current_context) { OpenStruct.new(form:, steps: []) }
          let(:result) { service.submit }

          it "raises an error" do
            expect { result }.to raise_error("Form id(1) has no completed steps i.e questions/answers to include in submission email")
          end
        end
      end

      context "when form being submitted is from previewed form" do
        let(:preview_mode) { true }

        it "calls FormSubmissionMailer" do
          freeze_time do
            allow(FormSubmissionMailer).to receive(:email_confirmation_input).and_call_original

            service.submit

            expect(FormSubmissionMailer).to have_received(:email_confirmation_input).with(
              { text_input: "# What is the meaning of life?\n42\n",
                notify_response_id: email_confirmation_input.submission_email_reference,
                submission_email: "testing@gov.uk",
                mailer_options: instance_of(FormSubmissionService::MailerOptions),
                csv_file: nil },
            ).once
          end
        end

        it "logs preview submission" do
          allow(LogEventService).to receive(:log_submit).once

          service.submit

          expect(LogEventService).to have_received(:log_submit).with(
            current_context,
            requested_email_confirmation: true,
            preview: true,
            csv_attached: false,
          )
        end

        describe "validations" do
          context "when form has no submission email" do
            let(:submission_email) { nil }

            it "does not raise an error" do
              expect { service.submit }.not_to raise_error
            end

            it "does not call the FormSubmissionMailer" do
              allow(FormSubmissionMailer).to receive(:email_confirmation_input).at_least(:once)

              service.submit

              expect(FormSubmissionMailer).not_to have_received(:email_confirmation_input)
            end
          end

          context "when from has no steps (i.e questions/answers)" do
            let(:current_context) { OpenStruct.new(form:, steps: []) }
            let(:result) { service.submit }

            it "raises an error" do
              expect { result }.to raise_error("Form id(1) has no completed steps i.e questions/answers to include in submission email")
            end
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

  describe "FormSubmissionService::NotifyTemplateBodyFilter" do
    let(:notify_template_body_filter) { NotifyTemplateFormatter.new }

    describe "#build_question_answers_section" do
      let(:form) { OpenStruct.new(completed_steps: [step]) }

      let(:step) { OpenStruct.new({ question_text: "What is the meaning of life?", show_answer_in_email: "42" }) }

      it "returns combined title and answer" do
        expect(notify_template_body_filter.build_question_answers_section(form)).to eq "# What is the meaning of life?\n42\n"
      end

      context "when there is more than one step" do
        let(:form) { OpenStruct.new(completed_steps: [step, step]) }

        it "contains a horizontal rule between each step" do
          expect(notify_template_body_filter.build_question_answers_section(form)).to include "\n\n---\n\n"
        end
      end
    end

    describe "#prep_question_title" do
      it "returns markdown heading on its own line" do
        klass = notify_template_body_filter
        ["Hello", "3.4 Question", "-23.4 Negative headings", "\n\n # 4.5.6"].each do |title|
          expect(klass.prep_question_title(title)).to eq "# #{title}\n"
        end
      end
    end

    describe "#prep_answer_text" do
      it "returns escaped answer" do
        [
          { input: "Hello", output: "Hello" },
          { input: "3.4 Question", output: "3\\.4 Question" },
          { input: "-23.4 answer", output: "\\-23\\.4 answer" },
          { input: "4.5.6", output: "4\\.5\\.6" },
          { input: "\n\n# Test \n\n## Test 2", output: "\\# Test\n\n\\#\\# Test 2" },
          { input: "\n\n```# Test 3\n\n## Test 4", output: "\\`\\`\\`\\# Test 3\n\n\\#\\# Test 4" }, # escapes ```
          { input: "\n\n\n\n\n```# Test \n\n\n\n\n\n## Test 3\n\n\n\n", output: "\\`\\`\\`\\# Test\n\n\\#\\# Test 3" },
          { input: "test https://example.org # more text 19.5\n\nA new paragraph.", output: "test https://example.org \\# more text 19\\.5\n\nA new paragraph\\." },
          { input: "test https://example.org # more text 19.5\n\nA new paragraph.\n\n# another link http://gov.uk", output: "test https://example.org \\# more text 19\\.5\n\nA new paragraph\\.\n\n\\# another link http://gov.uk" },
          { input: "not a title\n====", output: "not a title\n\\_\\_\\_\\_" },
          { input: "a normal sentence: 10 = 5 + 5", output: "a normal sentence: 10 = 5 \\+ 5" },
          { input: "    paragraph 1\n\n\n\n\n\n\n\n\n\n\n\n\n Another Paragraph with trailing space     \n\n\n\n\n", output: "paragraph 1\n\nAnother Paragraph with trailing space" },

        ].each do |test_case|
          expect(notify_template_body_filter.prep_answer_text(test_case[:input])).to eq test_case[:output]
        end
      end

      context "when answer is blank i.e skipped" do
        it "returns the blank answer text" do
          expect(notify_template_body_filter.prep_answer_text("")).to eq "\\[This question was skipped\\]"
        end
      end
    end
  end

private

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
