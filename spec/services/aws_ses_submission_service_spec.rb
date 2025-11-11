require "rails_helper"

RSpec.describe AwsSesSubmissionService do
  let(:service) { described_class.new(submission:) }

  let(:submission) do
    build(:submission, form_document:, reference: submission_reference, is_preview: is_preview,
                       created_at: Time.utc(2022, 12, 14, 8, 0o0, 0o0))
  end
  let(:form_document) { build(:v2_form_document, name: "A great form", submission_type:, submission_format:, submission_email:, payment_url:) }
  let(:all_steps) { [step] }
  let(:journey) { instance_double(Flow::Journey, completed_steps: all_steps, all_steps:, completed_file_upload_questions: []) }
  let(:question) { build :text, question_text: "What is the meaning of life?", text: "42" }
  let(:step) { build :step, question: }
  let(:is_preview) { false }
  let(:submission_reference) { Faker::Alphanumeric.alphanumeric(number: 8).upcase }
  let(:payment_url) { nil }
  let(:submission_type) { "email" }
  let(:submission_format) { [] }
  let(:submission_email) { "submissions@example.gov.uk" }
  let(:from_email_address) { "govukforms@example.gov.uk" }

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
      allow(CsvGenerator).to receive(:generate_submission).and_call_original
      allow(Settings.ses_submission_email).to receive(:from_email_address).and_return(from_email_address)
      allow(Flow::Journey).to receive(:new).and_return(journey)
    end

    shared_examples "it returns the message id" do
      it "returns the message id" do
        message_id = service.submit

        last_email = ActionMailer::Base.deliveries.last
        expect(message_id).to eq last_email.message_id
      end
    end

    context "when the submission type is email" do
      let(:submission_type) { "email" }
      let(:submission_format) { [] }

      it "calls AwsSesFormSubmissionMailer" do
        freeze_time do
          allow(AwsSesFormSubmissionMailer).to receive(:submission_email).and_call_original

          service.submit

          expect(AwsSesFormSubmissionMailer).to have_received(:submission_email).with(
            answer_content_html: "<h3>What is the meaning of life?</h3><p>42</p>",
            answer_content_plain_text: "What is the meaning of life?\n\n42",
            submission:,
            files: {},
            csv_filename: nil,
          ).once
        end
      end

      it "does not write a CSV file" do
        service.submit
        expect(CsvGenerator).not_to have_received(:generate_submission)
      end

      include_examples "it returns the message id"
    end

    context "when answers contain uploaded files" do
      let(:questions) { [question] }
      let(:question) { build :file, :with_uploaded_file }
      let(:journey) { instance_double(Flow::Journey, completed_steps: all_steps, all_steps:, completed_file_upload_questions: questions) }
      let(:file_content) { Faker::Lorem.sentence }

      before do
        allow(question).to receive(:file_from_s3).and_return(file_content)
      end

      it "calls AwsSesFormSubmissionMailer passing in the uploaded files" do
        allow(AwsSesFormSubmissionMailer).to receive(:submission_email).and_call_original

        service.submit

        expect(AwsSesFormSubmissionMailer).to have_received(:submission_email).with(
          answer_content_html: "<h3>#{question.question_text}</h3><p>#{I18n.t('mailer.submission.file_attached', filename: question.email_filename)}</p>",
          answer_content_plain_text: "#{question.question_text}\n\n#{I18n.t('mailer.submission.file_attached', filename: question.email_filename)}",
          submission:,
          files: { question.email_filename => file_content },
          csv_filename: nil,
        ).once
      end

      include_examples "it returns the message id"

      context "when uploaded_files_in_answers finds two files with the same name for the email attachment" do
        let(:questions) do
          [
            build(:file, :with_uploaded_file, original_filename: "my-uploaded-file.jpg"),
            build(:file, :with_uploaded_file, original_filename: "my-uploaded-file.jpg"),
          ]
        end

        before do
          questions.each do |question|
            allow(question).to receive(:file_from_s3).and_return(file_content)
          end
        end

        it "raises an error" do
          expect {
            service.submit
          }.to raise_error(/Duplicate email attachment filenames for submission/)
        end
      end

      context "when one or more file answers are missing the original filename" do
        let(:questions) do
          [
            build(:file, :with_uploaded_file, original_filename: ""),
            build(:file, :with_uploaded_file, original_filename: ""),
          ]
        end

        before do
          questions.each do |question|
            allow(question).to receive(:file_from_s3).and_return(file_content)
          end
        end

        it "raises an error" do
          expect {
            service.submit
          }.to raise_error(/file answers are invalid/)
        end
      end
    end

    context "when the submission type is email with csv" do
      let(:submission_type) { "email" }
      let(:submission_format) { %w[csv] }

      it "calls AwsSesFormSubmissionMailer passing in a CSV file" do
        allow(AwsSesFormSubmissionMailer).to receive(:submission_email).and_call_original

        service.submit

        expected_csv_content = "Reference,Submitted at,What is the meaning of life?\n#{submission_reference},2022-12-14T08:00:00+00:00,42\n"

        expect(AwsSesFormSubmissionMailer).to have_received(:submission_email).with(
          answer_content_html: "<h3>What is the meaning of life?</h3><p>42</p>",
          answer_content_plain_text: "What is the meaning of life?\n\n42",
          submission: submission,
          files: { "govuk_forms_a_great_form_#{submission_reference}.csv" => expected_csv_content },
          csv_filename: "govuk_forms_a_great_form_#{submission_reference}.csv",
        ).once
      end

      include_examples "it returns the message id"

      context "when submission contains a file upload question" do
        let(:question) { build :file, :with_uploaded_file }
        let(:journey) { instance_double(Flow::Journey, completed_steps: all_steps, all_steps:, completed_file_upload_questions: [question]) }
        let(:file_content) { Faker::Lorem.sentence }

        context "when the file upload question has been answered" do
          before do
            allow(question).to receive(:file_from_s3).and_return(file_content)
          end

          it "calls AwsSesFormSubmissionMailer passing in the CSV and the uploaded files" do
            allow(AwsSesFormSubmissionMailer).to receive(:submission_email).and_call_original

            service.submit

            expected_csv_content = "Reference,Submitted at,#{question.question_text}\n#{submission_reference},2022-12-14T08:00:00+00:00,#{question.email_filename}\n"

            expect(AwsSesFormSubmissionMailer).to have_received(:submission_email).with(
              answer_content_html: "<h3>#{question.question_text}</h3><p>#{I18n.t('mailer.submission.file_attached', filename: question.email_filename)}</p>",
              answer_content_plain_text: "#{question.question_text}\n\n#{I18n.t('mailer.submission.file_attached', filename: question.email_filename)}",
              submission:,
              files: {
                "govuk_forms_a_great_form_#{submission_reference}.csv" => expected_csv_content,
                question.email_filename => file_content,
              },
              csv_filename: "govuk_forms_a_great_form_#{submission_reference}.csv",
            ).once
          end
        end
      end
    end

    context "when the submission type is email with json" do
      let(:submission_type) { "email" }
      let(:submission_format) { %w[json] }

      it "calls AwsSesFormSubmissionMailer passing in a JSON file" do
        expect(AwsSesFormSubmissionMailer).to receive(:submission_email).with(
          hash_including(
            files: {
              "govuk_forms_a_great_form_#{submission_reference}.json" => satisfy do |json|
                JSON.parse(json)["form_name"] == "A great form"
              end,
            },
          ),
        ).and_call_original

        service.submit
      end
    end

    context "when the submission type is email with csv and json" do
      let(:submission_type) { "email" }
      let(:submission_format) { %w[csv json] }

      it "calls AwsSesFormSubmissionMailer passing in both a CSV and JSON file in the expected order" do
        json_filename = "govuk_forms_a_great_form_#{submission_reference}.json"
        csv_filename = "govuk_forms_a_great_form_#{submission_reference}.csv"

        expect(AwsSesFormSubmissionMailer).to receive(:submission_email).with(
          hash_including(
            files: satisfy { |files| files.keys == [json_filename, csv_filename] },
          ),
        ).and_call_original

        service.submit
      end
    end

    context "when form being submitted is from previewed form" do
      let(:is_preview) { true }

      context "when the submission email is set" do
        it "calls AwsSesFormSubmissionMailer" do
          allow(AwsSesFormSubmissionMailer).to receive(:submission_email).and_call_original

          service.submit

          expect(AwsSesFormSubmissionMailer).to have_received(:submission_email).with(
            answer_content_html: "<h3>What is the meaning of life?</h3><p>42</p>",
            answer_content_plain_text: "What is the meaning of life?\n\n42",
            submission:,
            files: {},
            csv_filename: nil,
          ).once
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

      include_examples "it returns the message id"
    end

    describe "validations" do
      context "when form has no submission email" do
        let(:submission_email) { nil }

        it "raises an error" do
          expect { service.submit }.to raise_error("Form id(#{form_document.form_id}) is missing a submission email address")
        end
      end
    end
  end
end
