require "rails_helper"

RSpec.describe JsonSubmissionGenerator do
  let(:form) { build :form, id: 1 }
  let(:text_question) { build :text, :with_answer, question_text: "What is the meaning of life?" }
  let(:name_question) { build :first_and_last_name_question, question_text: "What is your name?" }
  let(:file_question) { build :file, :with_uploaded_file, question_text: "Upload a file", original_filename: "test.txt" }
  let(:address_question) { build :uk_address_question, question_text: "What is your address?" }
  let(:selection_question) { build :multiple_selection_question, question_text: "Select your options" }
  let(:text_step) { build :step, page: build(:page, :with_text_settings), question: text_question }
  let(:name_step) { build :step, page: build(:page, answer_type: "name"), question: name_question }
  let(:file_step) { build :step, page: build(:page, answer_type: "file"), question: file_question }
  let(:address_step) { build :step, page: build(:page, :with_address_settings), question: address_question }
  let(:selection_step) { build :step, page: build(:page, :with_selections_settings), question: selection_question }
  let(:all_steps) { [text_step, name_step, file_step, address_step, selection_step] }
  let(:submission_reference) { Faker::Alphanumeric.alphanumeric(number: 8).upcase }
  let(:timestamp) do
    Time.use_zone("London") { Time.zone.local(2022, 9, 14, 8, 0, 0) }
  end

  describe ".generate_submission" do
    context "when the submission is being sent by email" do
      let(:is_s3_submission) { false }

      before do
        file_question.populate_email_filename(submission_reference:)
      end

      it "returns a string" do
        expect(described_class.generate_submission(form:, all_steps:, submission_reference:, timestamp:, is_s3_submission:)).to be_a(String)
      end

      it "returns JSON" do
        expect {
          JSON.parse(described_class.generate_submission(form:, all_steps:, submission_reference:, timestamp:, is_s3_submission:))
        }.not_to raise_error
      end

      it "outputs pretty printed JSON" do
        json_string = described_class.generate_submission(form:, all_steps:, submission_reference:, timestamp:, is_s3_submission:)
        expect(json_string).to include("\n  \"form_name\":")
        expect(json_string).to include("\n  \"answers\": [\n")
      end

      it "generates the submission JSON" do
        expect(
          JSON.parse(described_class.generate_submission(form:, all_steps:, submission_reference:, timestamp:, is_s3_submission:)),
        ).to eq({
          "$schema" => "http://localhost:3002/json-submissions/v1/schema",
          "form_name" => form.name,
          "submission_reference" => submission_reference,
          "submitted_at" => "2022-09-14T07:00:00.000Z",
          "answers" => [
            {
              "question_id" => text_step.page.id,
              "question_text" => "What is the meaning of life?",
              "answer_text" => text_question.text,
            },
            {
              "question_id" => name_step.page.id,
              "question_text" => "What is your name?",
              "first_name" => name_question.first_name,
              "last_name" => name_question.last_name,
              "answer_text" => name_question.show_answer,
            },
            {
              "question_id" => file_step.page.id,
              "question_text" => "Upload a file",
              "answer_text" => "test_#{submission_reference}.txt",
            },
            {
              "question_id" => address_step.page.id,
              "question_text" => "What is your address?",
              "address1" => address_question.address1,
              "address2" => "",
              "town_or_city" => address_question.town_or_city,
              "county" => address_question.county,
              "postcode" => address_question.postcode,
              "answer_text" => address_question.show_answer,
            },
            {
              "question_id" => selection_step.page.id,
              "question_text" => "Select your options",
              "selections" => ["Option 1", "Option 2"],
              "answer_text" => "Option 1, Option 2",
            },
          ],
        })
      end

      context "when there is a repeatable question" do
        let(:question_text) { "What is the meaning of life?" }
        let(:page) { build(:page, :with_text_settings, :with_repeatable, question_text:) }
        let(:first_answer) { build :text, question_text:, text: "dunno" }
        let(:second_answer) { build :text, question_text:, text: "42" }
        let(:repeatable_step) { build :repeatable_step, page:, questions: [first_answer, second_answer] }
        let(:all_steps) { [repeatable_step, name_step] }

        it "includes an entry for each question in the JSON" do
          expect(
            JSON.parse(described_class.generate_submission(form:, all_steps:, submission_reference:, timestamp:, is_s3_submission:)),
          ).to eq({
            "$schema" => "http://localhost:3002/json-submissions/v1/schema",
            "form_name" => form.name,
            "submission_reference" => submission_reference,
            "submitted_at" => "2022-09-14T07:00:00.000Z",
            "answers" => [
              {
                "question_id" => repeatable_step.page.id,
                "question_text" => "What is the meaning of life?",
                "can_have_multiple_answers" => true,
                "answer_text" => [first_answer.text, second_answer.text],
              },
              {
                "question_id" => name_step.page.id,
                "question_text" => "What is your name?",
                "first_name" => name_question.first_name,
                "last_name" => name_question.last_name,
                "answer_text" => name_question.show_answer,
              },
            ],
          })
        end
      end
    end

    context "when the submission is being sent to an S3 bucket" do
      let(:is_s3_submission) { true }

      it "generates JSON without including the submission reference in the filename for the file upload question" do
        json = JSON.parse(described_class.generate_submission(form:, all_steps:, submission_reference:, timestamp:, is_s3_submission:))
        expect(json["answers"]).to include({
          "question_id" => file_step.page.id,
          "question_text" => "Upload a file",
          "answer_text" => "test.txt",
        })
      end
    end
  end
end
