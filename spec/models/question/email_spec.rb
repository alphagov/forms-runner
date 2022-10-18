require "rails_helper"

RSpec.describe Question::Email, type: :model do
  let(:question) { described_class.new }

  it_behaves_like "a question model"

  context "when given an empty string or nil" do
    it "returns invalid with blank email" do
      expect(question).not_to be_valid
      expect(question.errors[:email]).to include(I18n.t("activemodel.errors.models.question/email.attributes.email.blank"))
    end

    it "returns invalid with empty string" do
      question.email = ""
      expect(question).not_to be_valid
      expect(question.errors[:email]).to include(I18n.t("activemodel.errors.models.question/email.attributes.email.blank"))
      expect(question.errors[:email]).not_to include(I18n.t("activemodel.errors.models.question/email.attributes.email.invalid_email"))
    end

    it "shows as a blank string" do
      expect(question.show_answer).to eq ""
    end
  end

  context "when given a string with an @ symbol in" do
    it "validates" do
      question.email = " @ "
      expect(question).to be_valid
    end
  end

  context "when given a string without an @ symbol in" do
    it "does not validate an address without an @" do
      question.email = "not an email address"
      expect(question).not_to be_valid
      expect(question.errors[:email]).to include(I18n.t("activemodel.errors.models.question/email.attributes.email.invalid_email"))
    end
  end

  context "when question is optional" do
    let(:question) { described_class.new({}, { is_optional: true }) }

    it "returns valid with blank email" do
      expect(question).to be_valid
      expect(question.errors[:email]).not_to include(I18n.t("activemodel.errors.models.question/email.attributes.email.blank"))
    end

    it "returns invalid with empty string" do
      question.email = ""
      expect(question).to be_valid
      expect(question.errors[:email]).not_to include(I18n.t("activemodel.errors.models.question/email.attributes.email.blank"))
      expect(question.errors[:email]).not_to include(I18n.t("activemodel.errors.models.question/email.attributes.email.invalid_email"))
    end

    it "shows as a blank string" do
      expect(question.show_answer).to eq ""
    end

    context "when given a string with an @ symbol in" do
      it "validates" do
        question.email = " @ "
        expect(question).to be_valid
      end
    end

    context "when given a string without an @ symbol in" do
      it "does not validate an address without an @" do
        question.email = "not an email address"
        expect(question).not_to be_valid
        expect(question.errors[:email]).to include(I18n.t("activemodel.errors.models.question/email.attributes.email.invalid_email"))
      end
    end
  end
end
