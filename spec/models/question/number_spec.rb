require "rails_helper"

RSpec.describe Question::Number, type: :model do
  subject(:question) { described_class.new({}, options) }

  let(:options) { { is_optional:, question_text: } }

  let(:is_optional) { false }
  let(:question_text) { Faker::Lorem.question }

  it_behaves_like "a question model"

  context "when given an empty string or nil" do
    it "returns invalid with blank message" do
      expect(question).not_to be_valid
      expect(question.errors[:number]).to include(I18n.t("activemodel.errors.models.question/number.attributes.number.blank"))
    end

    it "returns invalid with empty string" do
      question.number = ""
      expect(question).not_to be_valid
      expect(question.errors[:number]).to include(I18n.t("activemodel.errors.models.question/number.attributes.number.blank"))
    end

    it "shows as a blank string" do
      expect(question.show_answer).to eq ""
    end

    it "returns a hash with an blank value for show_answer_in_csv" do
      expect(question.show_answer_in_csv).to eq(Hash[question_text, ""])
    end
  end

  context "when given a whole number" do
    before do
      question.number = "299792458"
    end

    it "validates without errors" do
      expect(question).to be_valid
    end

    it "shows the answer" do
      expect(question.show_answer).to eq "299792458"
    end

    it "shows the answer in show_answer_in_csv" do
      expect(question.show_answer_in_csv).to eq(Hash[question_text, "299792458"])
    end
  end

  context "when given a decimal number" do
    before do
      question.number = "8.5"
    end

    it "validates without errors" do
      expect(question).to be_valid
    end

    it "shows the answer" do
      expect(question.show_answer).to eq "8.5"
    end

    it "shows the answer in show_answer_in_csv" do
      expect(question.show_answer_in_csv).to eq(Hash[question_text, "8.5"])
    end
  end

  context "when given a negative number" do
    it "returns a validation error" do
      question.number = "-1"
      expect(question).not_to be_valid
      expect(question.errors[:number]).to include(I18n.t("activemodel.errors.models.question/number.attributes.number.greater_than_or_equal_to"))
    end
  end

  context "when given a string which is not numeric" do
    it "returns a validation error" do
      question.number = "two"
      expect(question).not_to be_valid
      expect(question.errors[:number]).to include(I18n.t("activemodel.errors.models.question/number.attributes.number.not_a_number"))
    end
  end

  context "when question is optional" do
    let(:is_optional) { true }

    context "when given an empty string or nil" do
      it "returns invalid with blank message" do
        expect(question).to be_valid
        expect(question.errors[:number]).not_to include(I18n.t("activemodel.errors.models.question/number.attributes.number.blank"))
      end

      it "returns invalid with empty string" do
        question.number = ""
        expect(question).to be_valid
        expect(question.errors[:number]).not_to include(I18n.t("activemodel.errors.models.question/number.attributes.number.blank"))
      end

      it "shows as a blank string" do
        expect(question.show_answer).to eq ""
      end

      it "returns a hash with an blank value for show_answer_in_csv" do
        expect(question.show_answer_in_csv).to eq(Hash[question_text, ""])
      end
    end

    context "when given a whole number" do
      before do
        question.number = "299792458"
      end

      it "validates without errors" do
        expect(question).to be_valid
      end

      it "shows the answer" do
        expect(question.show_answer).to eq "299792458"
      end

      it "shows the answer in show_answer_in_csv" do
        expect(question.show_answer_in_csv).to eq(Hash[question_text, "299792458"])
      end
    end

    context "when given a decimal number" do
      before do
        question.number = "8.5"
      end

      it "validates without errors" do
        expect(question).to be_valid
      end

      it "shows the answer" do
        expect(question.show_answer).to eq "8.5"
      end

      it "shows the answer in show_answer_in_csv" do
        expect(question.show_answer_in_csv).to eq(Hash[question_text, "8.5"])
      end
    end

    context "when given a negative number" do
      it "returns a validation error" do
        question.number = "-1"
        expect(question).not_to be_valid
        expect(question.errors[:number]).to include(I18n.t("activemodel.errors.models.question/number.attributes.number.greater_than_or_equal_to"))
      end
    end

    context "when given a string which is not numeric" do
      it "returns a validation error" do
        question.number = "two"
        expect(question).not_to be_valid
        expect(question.errors[:number]).to include(I18n.t("activemodel.errors.models.question/number.attributes.number.not_a_number"))
      end
    end
  end
end
