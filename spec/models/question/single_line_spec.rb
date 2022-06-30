require "rails_helper"
require "shared_examples_for_question_models"

RSpec.describe Question::SingleLine, type: :model do
  it_behaves_like "a question model"

  it "validates presence" do
    question = described_class.new
    question.text = ""
    question.validate
    expect(question.errors[:text]).to include("can't be blank")

    question.text = "text"
    question.validate
    expect(question.errors[:text]).not_to include("can't be blank")
    expect(question).to be_valid
  end
end
