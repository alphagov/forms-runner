require "rails_helper"

RSpec.describe CsvGenerator do
  let(:form_document) { build(:v2_form_document, form_id: 42, available_languages:) }
  let(:submission) { build(:submission, form_document:, created_at: timestamp, reference: submission_reference, mode:, submission_locale:) }
  let(:page) { build :page }
  let(:text_question) { build :text, :with_answer, question_text: "What is the meaning of life?" }
  let(:name_question) { build :first_middle_last_name_question, question_text: "What is your name?" }
  let(:file_question) { build :file, :with_uploaded_file, question_text: "Upload a file", original_filename: "test.txt" }
  let(:first_step) { build :step, question: text_question }
  let(:second_step) { build :step, question: name_question }
  let(:third_step) { build :step, question: file_question }
  let(:all_steps) { [first_step, second_step, third_step] }
  let(:journey) { instance_double(Flow::Journey, all_steps:, completed_file_upload_questions: [file_question]) }
  let(:mode) { "form" }
  let(:submission_reference) { Faker::Alphanumeric.alphanumeric(number: 8).upcase }
  let(:submission_locale) { :en }
  let(:available_languages) { %w[en] }
  let(:timestamp) do
    Time.use_zone("London") { Time.zone.local(2022, 9, 14, 8, 0o0, 0o0) }
  end

  before do
    allow(Flow::Journey).to receive(:new).and_return(journey)
  end

  describe "#generate_submission" do
    subject(:csv) { described_class.generate_submission(submission:, is_s3_submission:) }

    context "when the submission is being sent by email" do
      let(:is_s3_submission) { false }

      it "returns a string" do
        expect(csv).to be_a(String)
      end

      it "generates the submission CSV" do
        expect(CSV.parse(csv)).to eq(
          [
            ["Reference", "Submitted at", "What is the meaning of life?", "What is your name? - First name", "What is your name? - Last name", "Upload a file"],
            [submission_reference, "2022-09-14T08:00:00+01:00", text_question.text, name_question.first_name, name_question.last_name, "test_#{submission_reference}.txt"],
          ],
        )
      end

      context "when a question is optional and answer is not provided" do
        let(:text_question) { build :text, question_text: "What is the meaning of life?", is_optional: true, text: nil }

        it "generates a CSV including blank column for unanswered optional question" do
          expect(CSV.parse(csv)).to eq(
            [
              ["Reference", "Submitted at", "What is the meaning of life?", "What is your name? - First name", "What is your name? - Last name", "Upload a file"],
              [submission_reference, "2022-09-14T08:00:00+01:00", "", name_question.first_name, name_question.last_name, "test_#{submission_reference}.txt"],
            ],
          )
        end
      end

      context "when there are repeated steps" do
        let(:name_question_repeated) { build :first_middle_last_name_question, question_text: "What is your name?" }
        let(:second_step) { build :repeatable_step, questions: [name_question, name_question_repeated] }

        it "generates a CSV with headers containing suffixes for the repeated steps" do
          expect(CSV.parse(csv)).to eq(
            [
              [
                "Reference",
                "Submitted at",
                "What is the meaning of life?",
                "What is your name? - First name - Answer 1",
                "What is your name? - Last name - Answer 1",
                "What is your name? - First name - Answer 2",
                "What is your name? - Last name - Answer 2",
                "Upload a file",
              ],
              [
                submission_reference,
                "2022-09-14T08:00:00+01:00",
                text_question.text,
                name_question.first_name,
                name_question.last_name,
                name_question_repeated.first_name,
                name_question_repeated.last_name,
                "test_#{submission_reference}.txt",
              ],
            ],
          )
        end
      end

      context "when the form has multiple available languages" do
        let(:available_languages) { %w[en cy] }

        it "generates the submission CSV with a language column" do
          expect(CSV.parse(csv)).to eq(
            [
              ["Reference", "Submitted at", "What is the meaning of life?", "What is your name? - First name", "What is your name? - Last name", "Upload a file", "Language"],
              [submission_reference, "2022-09-14T08:00:00+01:00", text_question.text, name_question.first_name, name_question.last_name, "test_#{submission_reference}.txt", "en"],
            ],
          )
        end
      end
    end

    context "when the submission is being sent to an S3 bucket" do
      let(:is_s3_submission) { true }

      it "generates a CSV without including the submission reference in the filename for the file upload question" do
        expect(CSV.parse(csv)).to eq(
          [
            ["Reference", "Submitted at", "What is the meaning of life?", "What is your name? - First name", "What is your name? - Last name", "Upload a file"],
            [submission_reference, "2022-09-14T08:00:00+01:00", text_question.text, name_question.first_name, name_question.last_name, file_question.original_filename],
          ],
        )
      end
    end
  end

  describe "#generate_batched_submissions" do
    subject(:csv) { described_class.generate_batched_submissions(submissions:, is_s3_submission:) }

    let(:submission_2) { build(:submission, form_document:, created_at: timestamp + 1.hour, reference: submission_reference_2, mode:, submission_locale: :cy) }
    let(:submission_reference_2) { Faker::Alphanumeric.alphanumeric(number: 8).upcase }
    let(:submissions) { [submission, submission_2] }
    let(:is_s3_submission) { false }

    it "generates a CSV with multiple rows for the submissions" do
      expect(CSV.parse(csv)).to eq(
        [
          ["Reference", "Submitted at", "What is the meaning of life?", "What is your name? - First name", "What is your name? - Last name", "Upload a file"],
          [submission_reference, "2022-09-14T08:00:00+01:00", text_question.text, name_question.first_name, name_question.last_name, "test_#{submission_reference}.txt"],
          [submission_reference_2, "2022-09-14T09:00:00+01:00", text_question.text, name_question.first_name, name_question.last_name, "test_#{submission_reference_2}.txt"],
        ],
      )
    end

    context "when the form has multiple available languages" do
      let(:available_languages) { %w[en cy] }

      it "generates a CSV with a language column" do
        expect(CSV.parse(csv)).to eq(
          [
            ["Reference", "Submitted at", "What is the meaning of life?", "What is your name? - First name", "What is your name? - Last name", "Upload a file", "Language"],
            [submission_reference, "2022-09-14T08:00:00+01:00", text_question.text, name_question.first_name, name_question.last_name, "test_#{submission_reference}.txt", "en"],
            [submission_reference_2, "2022-09-14T09:00:00+01:00", text_question.text, name_question.first_name, name_question.last_name, "test_#{submission_reference_2}.txt", "cy"],
          ],
        )
      end
    end

    context "when the CSV is being sent to an S3 bucket" do
      let(:is_s3_submission) { true }

      it "generates a CSV without including the submission reference in the filename for the file upload question" do
        expect(CSV.parse(csv)).to eq(
          [
            ["Reference", "Submitted at", "What is the meaning of life?", "What is your name? - First name", "What is your name? - Last name", "Upload a file"],
            [submission_reference, "2022-09-14T08:00:00+01:00", text_question.text, name_question.first_name, name_question.last_name, file_question.original_filename],
            [submission_reference_2, "2022-09-14T09:00:00+01:00", text_question.text, name_question.first_name, name_question.last_name, file_question.original_filename],
          ],
        )
      end
    end
  end
end
