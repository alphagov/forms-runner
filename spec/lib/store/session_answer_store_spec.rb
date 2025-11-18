require "rails_helper"
require "ostruct"

RSpec.describe Store::SessionAnswerStore do
  subject(:answer_store) { described_class.new(store, form_id) }

  let(:store) { {} }
  let(:form_id) { 1 }
  let(:step_id) { 5 }
  let(:database_id) { nil }
  let(:step) { instance_double(Step, { page_id: step_id, database_id: }) }
  let(:other_step) { OpenStruct.new({ page_id: "1" }) }
  let(:reference) { Faker::Alphanumeric.alphanumeric(number: 8).upcase }
  let(:requested_email_confirmation) { true }

  describe "answer store common methods" do
    let(:answer) { "test answer" }

    before do
      answer_store.save_step(step, answer)
    end

    it_behaves_like "an answer store"
  end

  it "stores the answer for a step" do
    answer_store.save_step(step, "test answer")
    result = answer_store.get_stored_answer(step)
    expect(result).to eq("test answer")
  end

  describe "#clear_stored_answer" do
    context "when the answer was stored using the step id as the key" do
      before do
        answer_store.save_step(step, "test answer")
      end

      it "clears a single answer for a step" do
        expect(answer_store.get_stored_answer(step)).to eq("test answer")
        answer_store.clear_stored_answer(step)
        expect(answer_store.get_stored_answer(step)).to be_nil
      end

      it "does not error if removing a step which doesn't exist in the store" do
        answer_store.clear_stored_answer(other_step)
        expect(answer_store.get_stored_answer(step)).to eq("test answer")
      end
    end

    context "when the the answer was stored using the database_id as the key" do
      let(:step_id) { "abcABC12" }
      let(:database_id) { 123 }
      let(:answer) { "test answer" }
      let(:store) do
        {
          answers: {
            form_id.to_s => {
              database_id.to_s => answer,
            },
          },
        }
      end

      it "clears a single answer for a step" do
        expect(answer_store.get_stored_answer(step)).to eq("test answer")
        answer_store.clear_stored_answer(step)
        expect(answer_store.get_stored_answer(step)).to be_nil
      end
    end

    context "when there are answers stored using both the id and database_id of the step" do
      let(:step_id) { "abcABC12" }
      let(:database_id) { 123 }
      let(:answer) { "test answer" }

      let(:store) do
        {
          answers: {
            form_id.to_s => {
              database_id.to_s => "an answer we will ignore",
              step_id => answer,
            },
          },
        }
      end

      it "clears both answers" do
        expect(answer_store.get_stored_answer(step)).to eq("test answer")
        answer_store.clear_stored_answer(step)
        expect(answer_store.answers).to eq({})
      end
    end
  end

  describe "#clear" do
    let(:other_form_id) { 9 }

    before do
      answer_store.save_step(step, "test answer")
    end

    it "clears the session for a form" do
      answer_store.clear
      expect(answer_store.get_stored_answer(step)).to be_nil
    end

    it "doesn't change other forms" do
      other_form_answer_store = described_class.new(store, other_form_id)
      other_form_answer_store.save_step(other_step, "other form answer")

      answer_store.clear
      expect(other_form_answer_store.get_stored_answer(other_step)).to eq("other form answer")
    end
  end

  describe "#get_stored_answer" do
    context "when the answer was stored using the step id as the key" do
      before do
        answer_store.save_step(step, "test answer")
        answer_store.save_step(other_step, "test2 answer")
      end

      it "returns the answer for the first step" do
        expect(answer_store.get_stored_answer(step)).to eq("test answer")
      end

      it "returns the answer for the second step" do
        expect(answer_store.get_stored_answer(other_step)).to eq("test2 answer")
      end
    end

    context "when the answer was stored using the database_id as the key" do
      let(:step_id) { "abcABC12" }
      let(:step_answer_store_key) { 123 }
      let(:answer) { "test answer" }
      let(:store) do
        {
          answers: {
            form_id.to_s => {
              step_answer_store_key.to_s => answer,
            },
          },
        }
      end

      context "when the step has a database_id" do
        let(:database_id) { step_answer_store_key }

        it "gets the answer by the database ID" do
          expect(answer_store.get_stored_answer(step)).to eq(answer)
        end
      end

      context "when the step does not have a database_id" do
        let(:database_id) { nil }

        it "returns nil" do
          expect(answer_store.get_stored_answer(step)).to be_nil
        end
      end
    end

    context "when there are answers stored using both the id and database_id of the step" do
      let(:step_id) { "abcABC12" }
      let(:database_id) { 123 }
      let(:answer) { "test answer" }

      let(:store) do
        {
          answers: {
            form_id.to_s => {
              database_id.to_s => "an answer we will ignore",
              step_id => answer,
            },
          },
        }
      end

      it "returns the answer stored using the step id" do
        expect(answer_store.get_stored_answer(step)).to eq(answer)
      end
    end
  end

  describe "#answers" do
    let(:form_answers) do
      {
        "1" => {
          selection: "Option 1",
        },
        "2" => {
          text: "Example text",
        },
      }
    end
    let(:store) do
      {
        answers: {
          form_id.to_s => form_answers,
          "2" => {
            "3" => {
              selection: "Option 2",
            },
          },
        },
      }
    end

    it "returns all answers for a form" do
      expect(answer_store.answers).to eq form_answers
    end
  end

  describe "#form_submitted?" do
    let(:store) { { answers: { form_id.to_s => nil } } }

    it "returns true when a form has been submitted and cleared" do
      expect(answer_store.form_submitted?).to be true
    end

    context "when form answers have not been submitted and cleared" do
      let(:store) { { answers: { form_id.to_s => "This is my answer to question 1" } } }

      it "returns true when a form has been submitted and cleared" do
        expect(answer_store.form_submitted?).to be false
      end
    end
  end
end
