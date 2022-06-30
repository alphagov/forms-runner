require "rails_helper"
require "shared_examples_for_question_models"

RSpec.describe Question::Email, type: :model do
  it_behaves_like "a question model"

  it "validates presence" do
    question = described_class.new
    question.email = ""
    question.validate
    expect(question.errors[:email]).to include("can't be blank")

    question.email = "email address"
    question.validate
    expect(question.errors[:email]).not_to include("can't be blank")
    expect(question).to be_valid
  end
end
