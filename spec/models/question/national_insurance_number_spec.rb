require "rails_helper"
require "shared_examples_for_question_models"

RSpec.describe Question::NationalInsuranceNumber, type: :model do
  it_behaves_like "a question model"

  context "when empty" do
    it "returns invalid" do
      question = described_class.new
      question.national_insurance_number = ""
      question.validate
      expect(question.errors[:national_insurance_number]).to include(I18n.t("activemodel.errors.models.question/national_insurance_number.attributes.national_insurance_number.blank"))
    end

    it "shows an answer if blank" do
      question = described_class.new
      question.national_insurance_number = ""
      question.validate
      expect(question.show_answer).to eq ""
    end
  end

  context "when given a correct number" do
    it "removes whitespace before valition presence" do
      question = described_class.new
      question.national_insurance_number = " J G 1 2 3 4 5 6 C "
      question.validate
      expect(question).to be_valid
    end

    it "shows answer in correct format" do
      question = described_class.new
      question.national_insurance_number = " J G 1 2 3 4 5 6 C "
      question.validate
      expect(question.show_answer).to eq "JG 12 34 56 C"
    end

    it "ignores case" do
      question = described_class.new
      question.national_insurance_number = " j g 1 2 3 4 5 6 C "
      question.validate
      expect(question).to be_valid
    end

    it "normlizes to uppercase" do
      question = described_class.new
      question.national_insurance_number = " j g 1 2 3 4 5 6 C "
      question.validate
      expect(question.show_answer).to eq "JG 12 34 56 C"
    end
  end

  context "when given an incorrect number" do
    it "doesn't validate incorrect NINOs" do
      question = described_class.new
      question.national_insurance_number = " Q Q 1 2 3 4 5 6 C "
      question.validate
      expect(question).not_to be_valid
    end
  end
end
