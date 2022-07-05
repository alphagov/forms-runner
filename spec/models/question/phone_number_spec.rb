require "rails_helper"
require "shared_examples_for_question_models"

RSpec.describe Question::PhoneNumber, type: :model do
  it_behaves_like "a question model"

  it "validates presence" do
    question = described_class.new
    question.phone_number = ""
    question.validate
    expect(question.errors[:phone_number]).to include("can't be blank")

    question.phone_number = "111"
    question.validate
    expect(question.errors[:phone_number]).not_to include("can't be blank")
    expect(question).to be_valid
  end
end
