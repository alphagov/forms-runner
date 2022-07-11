require "rails_helper"
require "shared_examples_for_question_models"

RSpec.describe Question::Email, type: :model do
  it_behaves_like "a question model"

  context "when given an empty string or nil" do
    it "returns invalid with blank message" do
      question = described_class.new
      question.validate
      expect(question.errors[:email]).to include(I18n.t("activemodel.errors.models.question/email.attributes.email.blank"))
      question.email = ""
      question.validate
      expect(question.errors[:email]).to include(I18n.t("activemodel.errors.models.question/email.attributes.email.blank"))
      expect(question.errors[:email]).not_to include(I18n.t("activemodel.errors.models.question/email.attributes.email.invalid_email"))
    end

    it "shows as a blank string" do
      question = described_class.new
      expect(question.show_answer).to eq ""
    end
  end

  context "when given a string with an @ symbol in" do
    it "validates" do
      question = described_class.new
      question.email = " @ "
      question.validate
      expect(question).to be_valid
    end
  end

  context "when given a string without an @ symbol in" do
    it "does not validate an address without an @" do
      question = described_class.new
      question.email = "not an email address"
      question.validate
      expect(question.errors[:email]).to include(I18n.t("activemodel.errors.models.question/email.attributes.email.invalid_email"))
    end
  end
end
