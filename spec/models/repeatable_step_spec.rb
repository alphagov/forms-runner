require "rails_helper"

RSpec.describe RepeatableStep, type: :model do
  subject(:repeatable_step) { described_class.new(question:, page:, form_id: 1, form_slug: "form-slug", next_page_slug: 2, page_slug: page.id) }

  let(:question) { build :name }
  let(:page) { build :page }

  describe "#repeatable?" do
    it "returns true" do
      expect(repeatable_step.repeatable?).to be true
    end
  end

  describe "#save_to_context" do
    let(:form_context) { instance_double(Flow::FormContext) }

    it "calls save_step on the argument" do
      allow(form_context).to receive(:save_step).with(repeatable_step, [question.serializable_hash])
      expect(repeatable_step.save_to_context(form_context)).to be(repeatable_step)
    end
  end

  describe "#load_from_context" do
    let(:form_context) { instance_double(Flow::FormContext) }

    context "when form context contains a non-array questions attribute" do
      it "raises an argument error" do
        allow(form_context).to receive(:get_stored_answer).with(repeatable_step).and_return("a string")
        expect { repeatable_step.load_from_context(form_context) }.to raise_error(ArgumentError)
      end
    end

    context "when form context contains an array questions attribute" do
      let(:question_attrs) { [first_attribute_hash, second_attribute_hash] }
      let(:first_attribute_hash) { { answer: "first" } }
      let(:second_attribute_hash) { { answer: "second" } }
      let(:question) { instance_double(Question::QuestionBase) }
      let(:question_dup) { instance_double(Question::QuestionBase) }

      it "builds the @questions array" do
        allow(form_context).to receive(:get_stored_answer).with(repeatable_step).and_return(question_attrs)
        allow(question).to receive(:dup).and_return(question_dup)
        expect(question_dup).to receive(:assign_attributes).with(first_attribute_hash)
        expect(question_dup).to receive(:assign_attributes).with(second_attribute_hash)

        expect(repeatable_step.load_from_context(form_context).questions).to eq([question_dup, question_dup])
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

    context "with 9 or fewer questions" do
      let(:questions) { [1, 2, 3, 4, 5, 6, 7, 8, 9] }

      it "returns false" do
        expect(repeatable_step.max_answers?).to be(false)
      end
    end

    context "with 10 questions" do
      let(:questions) { [1, 2, 3, 4, 5, 6, 7, 8, 9, 10] }

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
end
