require "rails_helper"

RSpec.describe Question::NationalInsuranceNumber, type: :model do
  subject(:question) { described_class.new({}, options) }

  let(:options) { { is_optional:, question_text: } }

  let(:is_optional) { false }
  let(:question_text) { Faker::Lorem.question }

  it_behaves_like "a question model"

  context "when given an empty string or nil" do
    it "returns invalid with blank ni number" do
      expect(question).not_to be_valid
      expect(question.errors[:national_insurance_number]).to include(I18n.t("activemodel.errors.models.question/national_insurance_number.attributes.national_insurance_number.blank"))
    end

    it "returns invalid with empty string" do
      question.national_insurance_number = ""
      expect(question).not_to be_valid
      expect(question.errors[:national_insurance_number]).to include(I18n.t("activemodel.errors.models.question/national_insurance_number.attributes.national_insurance_number.blank"))
    end

    it "shows an answer if blank" do
      expect(question.show_answer).to eq ""
    end

    it "returns a hash with an blank value for show_answer_in_csv" do
      expect(question.show_answer_in_csv).to eq(Hash[question_text, ""])
    end
  end

  context "when given a correct number" do
    before do
      question.national_insurance_number = " J G 1 2 3 4 5 6 C "
    end

    it "removes whitespace before validation presence" do
      expect(question).to be_valid
    end

    it "shows answer in correct format" do
      expect(question.show_answer).to eq "JG 12 34 56 C"
    end

    it "returns the answer in show_answer_in_csv" do
      expect(question.show_answer_in_csv).to eq(Hash[question_text, "JG 12 34 56 C"])
    end

    it "ignores case" do
      question.national_insurance_number = question.national_insurance_number.downcase
      expect(question).to be_valid
    end

    it "normlizes to uppercase" do
      question.national_insurance_number = question.national_insurance_number.downcase
      expect(question.show_answer).to eq "JG 12 34 56 C"
    end
  end

  context "when given an incorrect number" do
    it "doesn't validate incorrect NINOs" do
      question.national_insurance_number = " Q Q 1 2 3 4 5 6 C "
      expect(question).not_to be_valid
    end
  end

  context "when question is optional" do
    let(:is_optional) { true }

    context "when given an empty string or nil" do
      it "returns invalid with blank ni number" do
        expect(question).to be_valid
        expect(question.errors[:national_insurance_number]).not_to include(I18n.t("activemodel.errors.models.question/national_insurance_number.attributes.national_insurance_number.blank"))
      end

      it "returns invalid with empty string" do
        question.national_insurance_number = ""
        expect(question).to be_valid
        expect(question.errors[:national_insurance_number]).not_to include(I18n.t("activemodel.errors.models.question/national_insurance_number.attributes.national_insurance_number.blank"))
      end

      it "shows an answer if blank" do
        expect(question.show_answer).to eq ""
      end

      it "returns a hash with an blank value for show_answer_in_csv" do
        expect(question.show_answer_in_csv).to eq(Hash[question_text, ""])
      end
    end

    context "when given a correct number" do
      before do
        question.national_insurance_number = " J G 1 2 3 4 5 6 C "
      end

      it "removes whitespace before validation presence" do
        expect(question).to be_valid
      end

      it "shows answer in correct format" do
        expect(question.show_answer).to eq "JG 12 34 56 C"
      end

      it "returns the answer in show_answer_in_csv" do
        expect(question.show_answer_in_csv).to eq(Hash[question_text, "JG 12 34 56 C"])
      end

      it "ignores case" do
        question.national_insurance_number = question.national_insurance_number.downcase
        expect(question).to be_valid
      end

      it "normlizes to uppercase" do
        question.national_insurance_number = question.national_insurance_number.downcase
        expect(question.show_answer).to eq "JG 12 34 56 C"
      end
    end

    context "when given an incorrect number" do
      it "doesn't validate incorrect NINOs" do
        question.national_insurance_number = " Q Q 1 2 3 4 5 6 C "
        expect(question).not_to be_valid
      end
    end
  end
end
