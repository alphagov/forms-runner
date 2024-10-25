require "rails_helper"

RSpec.describe CsvGenerator do
  let(:form) { build :form, id: 1 }
  let(:page) { build :page }
  let(:text_question) { build :text, :with_answer, question_text: "What is the meaning of life?" }
  let(:name_question) { build :first_middle_last_name_question, question_text: "What is your name?" }
  let(:first_step) { build :step, question: text_question }
  let(:second_step) { build :step, question: name_question }
  let(:current_context) { OpenStruct.new(form:, completed_steps: [first_step, second_step], support_details: OpenStruct.new(call_back_url: "http://gov.uk")) }
  let(:submission_reference) { Faker::Alphanumeric.alphanumeric(number: 8).upcase }
  let(:timestamp) do
    Time.use_zone("London") { Time.zone.local(2022, 9, 14, 8, 0o0, 0o0) }
  end

  let(:test_file) { Tempfile.new("csv") }

  after do
    test_file.unlink
  end

  describe "#write" do
    before do
      described_class.write_submission(current_context:, submission_reference:, timestamp:, output_file_path: test_file.path)
    end

    it "writes submission to CSV file" do
      expect(CSV.open(test_file.path).readlines).to eq(
        [
          ["Reference", "Submitted at", "What is the meaning of life?", "What is your name? - First name", "What is your name? - Last name"],
          [submission_reference, "2022-09-14T08:00:00+01:00", text_question.text, name_question.first_name, name_question.last_name],
        ],
      )
    end

    context "when a question is optional and answer is not provided" do
      let(:text_question) { build :text, question_text: "What is the meaning of life?", is_optional: true, text: nil }

      it "writes submission to CSV file including blank column for unanswered optional question" do
        expect(CSV.open(test_file.path).readlines).to eq(
          [
            ["Reference", "Submitted at", "What is the meaning of life?", "What is your name? - First name", "What is your name? - Last name"],
            [submission_reference, "2022-09-14T08:00:00+01:00", "", name_question.first_name, name_question.last_name],
          ],
        )
      end
    end

    context "when there are repeated steps" do
      let(:name_question_repeated) { build :first_middle_last_name_question, question_text: "What is your name?" }
      let(:second_step) { build :repeatable_step, questions: [name_question, name_question_repeated] }

      it "writes submission to CSV file with headers containing suffixes for the repeated steps" do
        expect(CSV.open(test_file.path).readlines).to eq(
          [
            [
              "Reference",
              "Submitted at",
              "What is the meaning of life?",
              "What is your name? - First name - Answer 1",
              "What is your name? - Last name - Answer 1",
              "What is your name? - First name - Answer 2",
              "What is your name? - Last name - Answer 2",
            ],
            [
              submission_reference,
              "2022-09-14T08:00:00+01:00",
              text_question.text,
              name_question.first_name,
              name_question.last_name,
              name_question_repeated.first_name,
              name_question_repeated.last_name,
            ],
          ],
        )
      end
    end
  end
end
