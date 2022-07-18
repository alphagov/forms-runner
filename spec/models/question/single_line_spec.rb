require "rails_helper"
require "shared_examples_for_question_models"

RSpec.describe Question::SingleLine, type: :model do
  it_behaves_like "a question model"

  context "when given an empty string or nil" do
    it "returns invalid with blank message" do
      question = described_class.new
      question.validate
      expect(question.errors[:text]).to include(I18n.t("activemodel.errors.models.question/single_line.attributes.text.blank"))
      question.text = ""
      question.validate
      expect(question.errors[:text]).to include(I18n.t("activemodel.errors.models.question/single_line.attributes.text.blank"))
    end

    it "shows as a blank string" do
      question = described_class.new
      expect(question.show_answer).to eq ""
    end
  end

  context "when given a short string" do
    it "validates without errors" do
      question = described_class.new
      question.validate
      question.text = "testing"
      question.validate
      expect(question).to be_valid
    end
  end

  context "when given a string which is too long" do
    it "validates without errors" do
      question = described_class.new
      question.validate
      question.text = "a" * 500
      question.validate
      expect(question.errors[:text]).to include(I18n.t("activemodel.errors.models.question/single_line.attributes.text.too_long"))
    end
  end
end
