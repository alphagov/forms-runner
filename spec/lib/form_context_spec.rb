require "rails_helper"
require "ostruct"
require_relative "../../app/lib/form_context"

RSpec.describe FormContext do
  let(:store) { {} }
  let(:step) { OpenStruct.new({ page_id: "5", form_id: 1 }) }
  let(:step2) { OpenStruct.new({ page_id: "1", form_id: 2 }) }

  it "stores the answer for a step" do
    fc = described_class.new(store)
    fc.save_step(step, "test answer")
    result = fc.get_stored_answer(step)
    expect(result).to eq("test answer")
  end

  it "clears the session for a form" do
    fc = described_class.new(store)
    fc.save_step(step, "test answer")
    fc.clear(1)
    expect(fc.get_stored_answer(step)).to eq(nil)
  end

  it "clear on one form doesn't change other forms" do
    fc = described_class.new(store)
    fc2 = described_class.new(store)
    fc.save_step(step, "form1 answer")
    fc2.save_step(step2, "form2 answer")
    fc.clear(1)
    expect(fc2.get_stored_answer(step2)).to eq("form2 answer")
  end

  it "returns the answers for a form" do
    fc = described_class.new(store)
    fc.save_step(step, "test answer")
    fc.save_step(step2, "test2 answer")
    expect(fc.get_stored_answer(step)).to eq("test answer")
    expect(fc.get_stored_answer(step2)).to eq("test2 answer")
  end
end
