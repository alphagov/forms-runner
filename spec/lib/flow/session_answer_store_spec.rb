require "rails_helper"
require "ostruct"

RSpec.describe Flow::SessionAnswerStore do
  let(:store) { {} }
  let(:step) { OpenStruct.new({ page_id: "5", form_id: 1 }) }
  let(:other_form_step) { OpenStruct.new({ page_id: "1", form_id: 2 }) }
  let(:answer_store) { described_class.new(store) }
  let(:reference) { Faker::Alphanumeric.alphanumeric(number: 8).upcase }
  let(:requested_email_confirmation) { true }

  it "stores the answer for a step" do
    answer_store.save_step(step, "test answer")
    result = answer_store.get_stored_answer(step)
    expect(result).to eq("test answer")
  end

  it "clears a single answer for a step" do
    answer_store.save_step(step, "test answer")
    expect(answer_store.get_stored_answer(step)).to eq("test answer")
    answer_store.clear_stored_answer(step)
    expect(answer_store.get_stored_answer(step)).to be_nil
  end

  it "does not error if removing a step which doesn't exist in the store" do
    answer_store.save_step(step, "test answer")
    answer_store.clear_stored_answer(other_form_step)
    expect(answer_store.get_stored_answer(step)).to eq("test answer")
  end

  describe "#clear" do
    it "clears the session for a form" do
      answer_store.save_step(step, "test answer")
      answer_store.clear(1)
      expect(answer_store.get_stored_answer(step)).to be_nil
    end

    it "doesn't change other forms" do
      answer_store.save_step(step, "form1 answer")
      answer_store.save_step(other_form_step, "form2 answer")
      answer_store.clear(1)
      expect(answer_store.get_stored_answer(other_form_step)).to eq("form2 answer")
    end
  end

  it "returns the answers for a form" do
    answer_store.save_step(step, "test answer")
    answer_store.save_step(other_form_step, "test2 answer")
    expect(answer_store.get_stored_answer(step)).to eq("test answer")
    expect(answer_store.get_stored_answer(other_form_step)).to eq("test2 answer")
  end

  describe "#form_submitted?" do
    let(:store) { { answers: { "123" => nil } } }

    it "returns true when a form has been submitted and cleared" do
      expect(answer_store.form_submitted?(123)).to be true
    end

    context "when form answers have not been submitted and cleared" do
      let(:store) { { answers: { "123" => "This is my answer to question 1" } } }

      it "returns true when a form has been submitted and cleared" do
        expect(answer_store.form_submitted?(123)).to be false
      end
    end
  end
end
