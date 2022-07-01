require "rails_helper"
require "ostruct"
require_relative "../../app/lib/form_context"

RSpec.describe FormContext do
  let(:form) { OpenStruct.new({ id: "5" }) }
  let(:form2) { OpenStruct.new({ id: "8" }) }
  let(:page) { OpenStruct.new({ id: "1" }) }
  let(:page2) { OpenStruct.new({ id: "2" }) }

  it "stores the answer for a page" do
    fc = described_class.new({}, form)
    fc.store_answer(page, "test answer")
    result = fc.get_stored_answer(page)
    expect(result).to eq("test answer")
  end

  it "clears the session for a form" do
    fc = described_class.new({}, form)
    fc.store_answer(page, "test answer")
    fc.clear_answers
    expect(fc.answers).to eq({})
  end

  it "two doesn't change other forms" do
    session = {}
    fc = described_class.new(session, form)
    fc2 = described_class.new(session, form2)
    fc.store_answer(page, "form1 answer")
    fc2.store_answer(page2, "form2 answer")
    fc.clear_answers
    expect(fc2.answers).to eq({ "2" => "form2 answer" })
  end

  it "returns the answers for a form" do
    fc = described_class.new({}, form)
    fc.store_answer(page, "test answer")
    fc.store_answer(page2, "test2 answer")
    expect(fc.answers).to eq({ "1" => "test answer", "2" => "test2 answer" })
  end
end
