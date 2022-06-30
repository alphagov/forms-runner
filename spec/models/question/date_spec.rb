require "rails_helper"
require "shared_examples_for_question_models"

RSpec.describe Question::Date, type: :model do
  it_behaves_like "a question model"

  it "validates date" do
    question = described_class.new
    question.date = nil
    question.validate
    expect(question.errors[:date]).to include("is not a date")

    question.date = Date.new
    question.validate
    expect(question.errors[:date]).not_to include("is not a date")
    expect(question).to be_valid
  end

  it "displays date in the correct format" do
    question = described_class.new({ date: Date.parse("2021-12-31") })
    expect(question.show_answer).to eq "31/12/2021"
  end

  it "returns blank string with empty date" do
    question = described_class.new
    expect(question.show_answer).to eq ""
  end
end
