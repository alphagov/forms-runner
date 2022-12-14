require "rails_helper"

RSpec.describe Question::OrganisationName, type: :model do
  let(:question) { described_class.new }

  it_behaves_like "a question model"

  context "when given an empty string or nil" do
    it "returns invalid with blank message" do
      expect(question).not_to be_valid
      expect(question.errors[:text]).to include(I18n.t("activemodel.errors.models.question/organisation_name.attributes.text.blank"))
    end

    it "returns invalid with empty string" do
      question.text = ""
      expect(question).not_to be_valid
      expect(question.errors[:text]).to include(I18n.t("activemodel.errors.models.question/organisation_name.attributes.text.blank"))
    end

    it "shows as a blank string" do
      expect(question.show_answer).to eq ""
    end
  end

  context "when given a short string" do
    it "validates without errors" do
      question.text = "testing"
      expect(question).to be_valid
    end
  end

  context "when given a string which is too long" do
    it "validates without errors" do
      question.text = "a" * 500
      expect(question).not_to be_valid
      expect(question.errors[:text]).to include(I18n.t("activemodel.errors.models.question/organisation_name.attributes.text.too_long"))
    end
  end

  context "when question is optional" do
    let(:question) { described_class.new({}, { is_optional: true }) }

    context "when given an empty string or nil" do
      it "returns valid with blank message" do
        expect(question).to be_valid
        expect(question.errors[:text]).not_to include(I18n.t("activemodel.errors.models.question/organisation_name.attributes.text.blank"))
      end

      it "returns invalid with empty string" do
        question.text = ""
        expect(question).to be_valid
        expect(question.errors[:text]).not_to include(I18n.t("activemodel.errors.models.question/organisation_name.attributes.text.blank"))
      end

      it "shows as a blank string" do
        expect(question.show_answer).to eq ""
      end
    end

    context "when given a short string" do
      it "validates without errors" do
        question.text = "testing"
        expect(question).to be_valid
      end
    end

    context "when given a string which is too long" do
      it "validates without errors" do
        question.text = "a" * 500
        expect(question).not_to be_valid
        expect(question.errors[:text]).to include(I18n.t("activemodel.errors.models.question/organisation_name.attributes.text.too_long"))
      end
    end
  end
end
