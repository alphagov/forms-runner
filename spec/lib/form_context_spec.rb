require "rails_helper"
require "ostruct"
require_relative "../../app/lib/form_context"

RSpec.describe FormContext do
  let(:form) { OpenStruct.new({ id: "5" }) }
  let(:form2) { OpenStruct.new({ id: "8" }) }
  let(:page) { OpenStruct.new({ id: "1" }) }
  let(:page2) { OpenStruct.new({ id: "2" }) }

  it "stores the answer for a page" do
    jc = described_class.new({}, form)
    jc.store_answer(page, "test answer")
    result = jc.get_stored_answer(page)
    expect(result).to eq("test answer")
  end

  it "clears the session for a form" do
    jc = described_class.new({}, form)
    jc.store_answer(page, "test answer")
    jc.clear_answers
    expect(jc.answers).to eq({})
  end

  it "two doesnt effect other forms" do
    session = {}
    jc = described_class.new(session, form)
    jc2 = described_class.new(session, form2)
    jc.store_answer(page, "form1 answer")
    jc2.store_answer(page2, "form2 answer")
    jc.clear_answers
    expect(jc2.answers).to eq({ "2" => "form2 answer" })
  end

  it "returns the answers for a form" do
    jc = described_class.new({}, form)
    jc.store_answer(page, "test answer")
    jc.store_answer(page2, "test2 answer")
    expect(jc.answers).to eq({ "1" => "test answer", "2" => "test2 answer" })
  end
end
