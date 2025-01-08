require "rails_helper"

RSpec.describe AwsSesSubmissionService do
  let(:service) { described_class.new(current_context:, mailer_options:) }
  let(:form) do
    build(:form,
          id: 1,
          name: "Form 1",
          submission_email:,
          payment_url:)
  end
  let(:current_context) { OpenStruct.new(form:, completed_steps: [step], support_details: OpenStruct.new(call_back_url: "http://gov.uk")) }
  let(:question) { build :text, question_text: "What is the meaning of life?", text: "42" }
  let(:step) { build :step, question: }
  let(:preview_mode) { false }
  let(:submission_reference) { Faker::Alphanumeric.alphanumeric(number: 8).upcase }
  let(:payment_url) { nil }
  let(:submission_email) { "submissions@example.gov.uk" }
  let(:from_email_address) { "govukforms@example.gov.uk" }
  let(:timestamp) { Time.utc(2022, 9, 14, 8, 0o0, 0o0) }
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
      allow(CsvGenerator).to receive(:write_submission).and_call_original
      allow(Settings.ses_submission_email).to receive(:from_email_address).and_return(from_email_address)
    end

    context "when the submission type is email" do
      before do
        form.submission_type = "email"
      end

      it "calls AwsSesFormSubmissionMailer" do
        freeze_time do
          allow(AwsSesFormSubmissionMailer).to receive(:submission_email).and_call_original

          service.submit

          expect(AwsSesFormSubmissionMailer).to have_received(:submission_email).with(
            { answer_content: "<h2>What is the meaning of life?</h2><p>42</p>",
              submission_email_address: submission_email,
              mailer_options: instance_of(FormSubmissionService::MailerOptions),
              files: {} },
          ).once
        end
      end

      it "does not write a CSV file" do
        service.submit
        expect(CsvGenerator).not_to have_received(:write_submission)
      end
    end

    context "when answers contain uploaded files" do
      let(:question) { build :file, :with_uploaded_file }
      let(:file_content) { Faker::Lorem.sentence }

      before do
        allow(question).to receive(:file_from_s3).and_return(file_content)
      end

      it "calls AwsSesFormSubmissionMailer passing in the uploaded files" do
        travel_to timestamp do
          allow(AwsSesFormSubmissionMailer).to receive(:submission_email).and_call_original

          service.submit

          expect(AwsSesFormSubmissionMailer).to have_received(:submission_email).with(
            { answer_content: "<h2>#{question.question_text}</h2><p>#{question.original_filename}</p>",
              submission_email_address: submission_email,
              mailer_options: instance_of(FormSubmissionService::MailerOptions),
              files: { question.original_filename => file_content } },
          ).once
        end
      end
    end

    context "when the submission type is email_with_csv" do
      before do
        form.submission_type = "email_with_csv"
      end

      it "writes a CSV file" do
        travel_to timestamp do
          service.submit
          expect(CsvGenerator).to have_received(:write_submission)
                                    .with(current_context:,
                                          submission_reference:,
                                          timestamp:,
                                          output_file_path: an_instance_of(String))
        end
      end

      it "calls AwsSesFormSubmissionMailer passing in a CSV file" do
        travel_to timestamp do
          allow(AwsSesFormSubmissionMailer).to receive(:submission_email).and_call_original

          service.submit

          expected_csv_content = "Reference,Submitted at,What is the meaning of life?\n#{submission_reference},2022-09-14T08:00:00Z,42\n"

          expect(AwsSesFormSubmissionMailer).to have_received(:submission_email).with(
            { answer_content: "<h2>What is the meaning of life?</h2><p>42</p>",
              submission_email_address: submission_email,
              mailer_options: instance_of(FormSubmissionService::MailerOptions),
              files: { "govuk_forms_form_#{form.id}_#{submission_reference}.csv" => expected_csv_content } },
          ).once
        end
      end

      context "when submission contains a file upload question" do
        let(:question) { build :file, :with_uploaded_file }
        let(:file_content) { Faker::Lorem.sentence }

        context "when the file upload question has been answered" do
          before do
            allow(question).to receive(:file_from_s3).and_return(file_content)
          end

          it "calls AwsSesFormSubmissionMailer passing in the CSV and the uploaded files" do
            travel_to timestamp do
              allow(AwsSesFormSubmissionMailer).to receive(:submission_email).and_call_original

              service.submit

              expected_csv_content = "Reference,Submitted at,#{question.question_text}\n#{submission_reference},2022-09-14T08:00:00Z,#{question.original_filename}\n"

              expect(AwsSesFormSubmissionMailer).to have_received(:submission_email).with(
                { answer_content: "<h2>#{question.question_text}</h2><p>#{question.original_filename}</p>",
                  submission_email_address: submission_email,
                  mailer_options: instance_of(FormSubmissionService::MailerOptions),
                  files: {
                    "govuk_forms_form_#{form.id}_#{submission_reference}.csv" => expected_csv_content,
                    question.original_filename => file_content,
                  } },
              ).once
            end
          end
        end

        context "when the file upload question has been skipped" do
          let(:question) { build :file, :with_answer_skipped }

          it "calls AwsSesFormSubmissionMailer without including a file for the unanswered question" do
            travel_to timestamp do
              allow(AwsSesFormSubmissionMailer).to receive(:submission_email).and_call_original

              service.submit

              expected_csv_content = "Reference,Submitted at,#{question.question_text}\n#{submission_reference},2022-09-14T08:00:00Z,\"\"\n"

              expect(AwsSesFormSubmissionMailer).to have_received(:submission_email).with(
                { answer_content: "<h2>#{question.question_text}</h2><p>[This question was skipped]</p>",
                  submission_email_address: submission_email,
                  mailer_options: instance_of(FormSubmissionService::MailerOptions),
                  files: {
                    "govuk_forms_form_#{form.id}_#{submission_reference}.csv" => expected_csv_content,
                  } },
              ).once
            end
          end
        end
      end
    end

    context "when form being submitted is from previewed form" do
      let(:preview_mode) { true }

      context "when the submission email is set" do
        it "calls AwsSesFormSubmissionMailer" do
          travel_to timestamp do
            allow(AwsSesFormSubmissionMailer).to receive(:submission_email).and_call_original

            service.submit

            expect(AwsSesFormSubmissionMailer).to have_received(:submission_email).with(
              { answer_content: "<h2>What is the meaning of life?</h2><p>42</p>",
                submission_email_address: submission_email,
                mailer_options: instance_of(FormSubmissionService::MailerOptions),
                files: {} },
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
          allow(AwsSesFormSubmissionMailer).to receive(:submission_email).and_call_original
          service.submit
          expect(AwsSesFormSubmissionMailer).not_to have_received(:submission_email)
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
