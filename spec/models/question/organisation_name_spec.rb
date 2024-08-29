require "rails_helper"

RSpec.describe Question::OrganisationName, type: :model do
  subject(:question) { described_class.new({}, options) }

  let(:options) { { is_optional:, question_text: } }

  let(:is_optional) { false }
  let(:question_text) { Faker::Lorem.question }

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

    it "returns an empty hash for show_answer_in_csv" do
      expect(question.show_answer_in_csv).to eq({})
    end
  end

  context "when given a short string" do
    before do
      question.text = "testing"
    end

    it "validates without errors" do
      question.text = "testing"
      expect(question).to be_valid
    end

    it "shows the answer" do
      expect(question.show_answer).to eq("testing")
    end

    it "shows the answer in show_answer_in_csv" do
      expect(question.show_answer_in_csv).to eq(Hash[question_text, "testing"])
    end
  end

  context "when given a string which is too long" do
    it "returns invalid with too long message" do
      question.text = "a" * 500
      expect(question).not_to be_valid
      expect(question.errors[:text]).to include(I18n.t("activemodel.errors.models.question/organisation_name.attributes.text.too_long"))
    end
  end

  context "when question is optional" do
    let(:is_optional) { true }

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

      it "returns an empty hash for show_answer_in_csv" do
        expect(question.show_answer_in_csv).to eq({})
      end
    end

    context "when given a short string" do
      before do
        question.text = "testing"
      end

      it "validates without errors" do
        expect(question).to be_valid
      end

      it "shows the answer" do
        expect(question.show_answer).to eq("testing")
      end

      it "shows the answer in show_answer_in_csv" do
        expect(question.show_answer_in_csv).to eq(Hash[question_text, "testing"])
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
