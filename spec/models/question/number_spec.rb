require "rails_helper"
require "shared_examples_for_question_models"

RSpec.describe Question::Number, type: :model do
  it_behaves_like "a question model"

  context "when given an empty string or nil" do
    it "returns invalid with blank message" do
      question = described_class.new
      expect(question).not_to be_valid
      expect(question.errors[:number]).to include(I18n.t("activemodel.errors.models.question/number.attributes.number.blank"))
      question.number = ""
      expect(question).not_to be_valid
      expect(question.errors[:number]).to include(I18n.t("activemodel.errors.models.question/number.attributes.number.blank"))
    end

    it "shows as a blank string" do
      question = described_class.new
      expect(question.show_answer).to eq ""
    end
  end

  context "when given a whole number" do
    it "validates without errors" do
      question = described_class.new(number: "299792458")
      expect(question).to be_valid
    end
  end

  context "when given a decimal number" do
    it "validates without errors" do
      question = described_class.new(number: "8.5")
      expect(question).to be_valid
    end
  end

  context "when given a negative number" do
    it "returns a validation error" do
      question = described_class.new(number: "-1")
      expect(question).not_to be_valid
      expect(question.errors[:number]).to include(I18n.t("activemodel.errors.models.question/number.attributes.number.greater_than_or_equal_to"))
    end
  end

  context "when given a string which is not numeric" do
    it "returns a validation error" do
      question = described_class.new(number: "two")
      expect(question).not_to be_valid
      expect(question.errors[:number]).to include(I18n.t("activemodel.errors.models.question/number.attributes.number.not_a_number"))
    end
  end
end
