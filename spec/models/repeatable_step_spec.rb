require "rails_helper"

RSpec.describe RepeatableStep, type: :model do
  subject(:repeatable_step) { described_class.new(question:, page:, form:, next_page_slug: 2, page_slug: page.id) }

  let(:form) { build :form, id: 1, form_slug: "form-slug", pages: [page, build(:page, id: 2)] }
  let(:page) { build :page }
  let(:question) { build :name, is_optional: false }

  describe "#repeatable?" do
    it "returns true" do
      expect(repeatable_step.repeatable?).to be true
    end
  end

  describe "#save_to_context" do
    let(:answer_store) { instance_double(Store::SessionAnswerStore) }

    it "calls save_step on the argument" do
      allow(answer_store).to receive(:save_step).with(repeatable_step, [question.serializable_hash])
      expect(repeatable_step.save_to_store(answer_store)).to be(repeatable_step)
    end
  end

  describe "#load_from_context" do
    let(:answer_store) { instance_double(Store::SessionAnswerStore) }

    context "when form context contains a non-array questions attribute" do
      it "raises an argument error" do
        allow(answer_store).to receive(:get_stored_answer).with(repeatable_step).and_return("a string")
        expect { repeatable_step.load_from_store(answer_store) }.to raise_error(ArgumentError)
      end
    end

    context "when form context contains an array questions attribute" do
      let(:question_attrs) { [first_attribute_hash, second_attribute_hash] }
      let(:first_attribute_hash) { { answer: "first" } }
      let(:second_attribute_hash) { { answer: "second" } }
      let(:question) { instance_double(Question::QuestionBase) }
      let(:question_dup) { instance_double(Question::QuestionBase) }

      it "builds the @questions array" do
        allow(answer_store).to receive(:get_stored_answer).with(repeatable_step).and_return(question_attrs)
        allow(question).to receive(:dup).and_return(question_dup)
        expect(question_dup).to receive(:assign_attributes).with(first_attribute_hash)
        expect(question_dup).to receive(:assign_attributes).with(second_attribute_hash)

        expect(repeatable_step.load_from_store(answer_store).questions).to eq([question_dup, question_dup])
      end
    end
  end

  describe "#question" do
    let(:questions) { [1] }

    before do
      allow(question).to receive(:dup).and_return(1, 2, 3)
      repeatable_step.answer_index = answer_index
      repeatable_step.questions = questions
    end

    context "when the answer index is blank" do
      let(:answer_index) { nil }

      it "returns the first question" do
        expect(repeatable_step.question).to eq(1)
      end
    end

    context "when the answer index is exactly 1 greater than the questions length" do
      let(:answer_index) { 2 }

      it "duplicates question and adds it to the questions list" do
        expect(repeatable_step.question).to eq(2)
        expect(repeatable_step.questions).to eq([1, 2])
      end
    end

    context "when the answer index is outside the range of the questions list" do
      let(:answer_index) { 3 }

      it "raises an AnswerIndexError" do
        expect { repeatable_step.question }.to raise_error(RepeatableStep::AnswerIndexError)
      end
    end

    context "when the answer index is within the range of the questions list" do
      let(:answer_index) { 3 }
      let(:questions) { [1, 2, 3] }

      it "returns the question at that index" do
        expect(repeatable_step.question).to eq(3)
      end
    end
  end

  describe "#next_answer_index" do
    let(:questions) { [1, 2, 3] }

    before { repeatable_step.questions = questions }

    it "returns an index for the next question iteration" do
      expect(repeatable_step.next_answer_index).to eq(4)
    end
  end

  describe "#max_answers?" do
    before { repeatable_step.questions = questions }

    context "with 49 or fewer questions" do
      let(:questions) { Array.new(49, :a_default_value) }

      it "returns false" do
        expect(repeatable_step.max_answers?).to be(false)
      end
    end

    context "with 50 questions" do
      let(:questions) { Array.new(50, :a_default_value) }

      it "returns true" do
        expect(repeatable_step.max_answers?).to be(true)
      end
    end
  end

  describe "#show_answer" do
    let(:questions) { [first_question, second_question] }
    let(:first_question) { OpenStruct.new({ show_answer: "first answer" }) }
    let(:second_question) { OpenStruct.new({ show_answer: "second answer" }) }

    before { repeatable_step.questions = questions }

    it "returns an ordered list of answers" do
      expect(repeatable_step.show_answer).to eq('<ol class="govuk-list govuk-list--number"><li>first answer</li><li>second answer</li></ol>')
    end

    context "when the question is optional and has been skipped" do
      let(:questions) { [OpenStruct.new({ show_answer: "" })] }

      it "returns blank" do
        expect(repeatable_step.show_answer).to be_blank
      end
    end
  end

  describe "#show_answer_in_email" do
    let(:questions) { [first_question, second_question] }
    let(:first_question) { OpenStruct.new({ show_answer_in_email: "first answer" }) }
    let(:second_question) { OpenStruct.new({ show_answer_in_email: "second answer" }) }

    before { repeatable_step.questions = questions }

    it "returns an ordered list of answers" do
      expect(repeatable_step.show_answer_in_email).to eq("1. first answer\n\n2. second answer")
    end
  end

  describe "#show_answer_in_csv" do
    let(:first_question) { build :first_middle_last_name_question, question_text: "What is your name?" }
    let(:second_question) { build :first_middle_last_name_question, question_text: "What is your name?" }

    context "when the question has multiple attributes" do
      before do
        repeatable_step.questions = [first_question, second_question]
      end

      it "returns a hash of all answers with keys containing the answer numbers" do
        # we convert to an array to test the ordering of the hash
        expect(repeatable_step.show_answer_in_csv(false).to_a).to eq({
          "What is your name? - First name - Answer 1" => first_question.first_name,
          "What is your name? - Last name - Answer 1" => first_question.last_name,
          "What is your name? - First name - Answer 2" => second_question.first_name,
          "What is your name? - Last name - Answer 2" => second_question.last_name,
        }.to_a)
      end
    end

    context "when the question has a single attribute" do
      let(:first_question) { build :text, :with_answer, question_text: "What is the meaning of life?" }
      let(:second_question) { build :text, :with_answer, question_text: "What is the meaning of life?" }

      before do
        repeatable_step.questions = [first_question, second_question]
      end

      it "returns a hash of all answers with keys containing the answer numbers" do
        # we convert to an array to test the ordering of the hash
        expect(repeatable_step.show_answer_in_csv(false).to_a).to eq({
          "What is the meaning of life? - Answer 1" => first_question.text,
          "What is the meaning of life? - Answer 2" => second_question.text,
        }.to_a)
      end
    end

    context "when the question is optional and has no answers" do
      let(:question) { build :text, is_optional: false }

      it "returns a hash containing a key for the first answer with a blank value" do
        expect(repeatable_step.show_answer_in_csv(false)).to eq({
          "#{question.question_text} - Answer 1" => "",
        })
      end
    end
  end

  describe "#remove_answer" do
    let(:questions) { [first_question, second_question] }
    let(:first_question) { OpenStruct.new({ show_answer_in_email: "first answer" }) }
    let(:second_question) { OpenStruct.new({ show_answer_in_email: "second answer" }) }

    before { repeatable_step.questions = questions }

    it "removes a question at the given answer index - 1" do
      repeatable_step.remove_answer(2)
      expect(repeatable_step.questions).to eq([first_question])
    end

    context "when removing an answer leaves questions empty" do
      let(:questions) { [first_question] }

      before { repeatable_step.answer_index = 1 }

      it "adds a blank answer" do
        repeatable_step.remove_answer(1)
        expect(repeatable_step.questions.first.question_text).to eq(question.question_text)
      end
    end
  end

  describe "#valid?" do
    let(:questions) { [first_question, second_question] }
    let(:first_question) { OpenStruct.new({ valid?: true }) }
    let(:second_question) { OpenStruct.new({ valid?: true }) }

    before { repeatable_step.questions = questions }

    context "when all questions are valid" do
      it "returns true" do
        expect(repeatable_step).to be_valid
      end
    end

    context "when a questions is not valid" do
      let(:second_question) { OpenStruct.new({ valid?: false }) }

      it "returns true" do
        expect(repeatable_step).not_to be_valid
      end
    end
  end

  describe "#min_answers?" do
    before { repeatable_step.questions = questions }

    context "when there is one value in questions" do
      let(:questions) { [first_question] }
      let(:first_question) { OpenStruct.new }

      it "returns true" do
        expect(repeatable_step).to be_min_answers
      end

      context "when the question is optional" do
        let(:question) { build :name, is_optional: true }

        it "returns false" do
          expect(repeatable_step).not_to be_min_answers
        end
      end
    end

    context "when there are at least two values in questions" do
      let(:questions) { [first_question, second_question] }
      let(:first_question) { OpenStruct.new }
      let(:second_question) { OpenStruct.new }

      it "returns true" do
        expect(repeatable_step).not_to be_min_answers
      end
    end
  end
end
