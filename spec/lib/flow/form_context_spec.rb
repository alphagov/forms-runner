require "rails_helper"
require "ostruct"

RSpec.describe Flow::FormContext do
  let(:store) { {} }
  let(:step) { OpenStruct.new({ page_id: "5", form_id: 1 }) }
  let(:step2) { OpenStruct.new({ page_id: "1", form_id: 2 }) }
  let(:form_context) { described_class.new(store) }
  let(:reference) { Faker::Alphanumeric.alphanumeric(number: 8).upcase }
  let(:requested_email_confirmation) { true }

  it "stores the answer for a step" do
    form_context.save_step(step, "test answer")
    result = form_context.get_stored_answer(step)
    expect(result).to eq("test answer")
  end

  it "clears a single answer for a step" do
    form_context.save_step(step, "test answer")
    expect(form_context.get_stored_answer(step)).to eq("test answer")
    form_context.clear_stored_answer(step)
    expect(form_context.get_stored_answer(step)).to be_nil
  end

  it "does not error if removing a step which doesn't exist in the store" do
    form_context.save_step(step, "test answer")
    form_context.clear_stored_answer(step2)
    expect(form_context.get_stored_answer(step)).to eq("test answer")
  end

  describe "#clear" do
    it "clears the session for a form" do
      form_context.save_step(step, "test answer")
      form_context.clear(1)
      expect(form_context.get_stored_answer(step)).to be_nil
    end

    it "doesn't change other forms" do
      fc2 = described_class.new(store)
      form_context.save_step(step, "form1 answer")
      fc2.save_step(step2, "form2 answer")
      form_context.clear(1)
      expect(fc2.get_stored_answer(step2)).to eq("form2 answer")
    end
    end
  end

  it "returns the answers for a form" do
    form_context.save_step(step, "test answer")
    form_context.save_step(step2, "test2 answer")
    expect(form_context.get_stored_answer(step)).to eq("test answer")
    expect(form_context.get_stored_answer(step2)).to eq("test2 answer")
  end

  describe "#form_submitted?" do
    let(:store) { { answers: { "123" => nil } } }

    it "returns true when a form has been submitted and cleared" do
      expect(form_context.form_submitted?(123)).to be true
    end

    context "when form answers have not been submitted and cleared" do
      let(:store) { { answers: { "123" => "This is my answer to question 1" } } }

      it "returns true when a form has been submitted and cleared" do
        expect(form_context.form_submitted?(123)).to be false
      end
    end
  end
end
