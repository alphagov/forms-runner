require "rails_helper"
require "shared_examples_for_question_models"

RSpec.describe Question::NationalInsuranceNumber, type: :model do
  it_behaves_like "a question model"

  it "validates presence" do
    question = described_class.new
    question.national_insurance_number = ""
    question.validate
    expect(question.errors[:national_insurance_number]).to include("can't be blank")

    question.national_insurance_number = "nino"
    question.validate
    expect(question.errors[:national_insurance_number]).not_to include("can't be blank")
    expect(question).to be_valid
  end
end
