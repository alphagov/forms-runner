require "rails_helper"
require "shared_examples_for_question_models"

RSpec.describe Question::PhoneNumber, type: :model do
  let(:question) { described_class.new }

  let(:valid_phone_numbers) do
    [
      "+447123 123 123",
      "+407123 123 123",
      "+1 7123 123 123",
      "+447123123123",
      "07123123123",
      "01234 123 123 --()+ ",
      "01234 123 123 ext 123",
      "01234 123 123 x123",
      "(01234) 123123",
      "(12345) 123123",
      "(+44) (0)1234 123456",
      "+44 (0) 123 4567 123",
      "123 1234 1234 ext 123",
      "12345 123456 ext 123",
      "12345 123456 ext. 123",
      "12345 123456 ext123",
      "01234123456 ext 123",
      "123 1234 1234 x123",
      "12345 123456 x123",
      "12345123456 x123",
      "(1234) 123 1234",
      "1234 123 1234 x123",
      "1234 123 1234 ext 1234",
      "1234 123 1234  ext 123",
      "+44(0)123 12 12345",
    ]
  end

  it_behaves_like "a question model"

  context "when a phone number is empty or blank" do
    it "returns invalid with blank phone number" do
      expect(question).not_to be_valid
      expect(question.errors[:phone_number]).to include(I18n.t("activemodel.errors.models.question/phone_number.attributes.phone_number.blank"))
    end

    it "returns invalid with empty string" do
      question.phone_number = ""
      expect(question).not_to be_valid
      expect(question.errors[:phone_number]).to include(I18n.t("activemodel.errors.models.question/phone_number.attributes.phone_number.blank"))
    end
  end

  context "when a phone number is valid" do
    it "validates correctly" do
      valid_phone_numbers.each do |number|
        question.phone_number = number
        expect(question).to be_valid
      end
    end
  end

  context "when phone number is over 15 numbers" do
    it "returns an error" do
      question.phone_number = "123456791123456789"
      expect(question).not_to be_valid

      expect(question.errors[:phone_number]).to include(I18n.t("activemodel.errors.models.question/phone_number.attributes.phone_number.phone_too_long"))
    end
  end

  context "when phone number is 7 numbers or less" do
    it "returns an error" do
      question.phone_number = "1234567"
      expect(question).not_to be_valid

      expect(question.errors[:phone_number]).to include(I18n.t("activemodel.errors.models.question/phone_number.attributes.phone_number.phone_too_short"))
    end
  end


  context "when question is optional" do
    let(:question) { described_class.new({}, { is_optional: true }) }

    context "when a phone number is empty or blank" do
      it "returns valid with blank phone number" do
        expect(question).to be_valid
        expect(question.errors[:phone_number]).not_to include(I18n.t("activemodel.errors.models.question/phone_number.attributes.phone_number.blank"))
      end

      it "returns invalid with empty string" do
        question.phone_number = ""
        expect(question).to be_valid
        expect(question.errors[:phone_number]).not_to include(I18n.t("activemodel.errors.models.question/phone_number.attributes.phone_number.blank"))
      end
    end

    context "when a phone number is valid" do
      it "validates correctly" do
        valid_phone_numbers.each do |number|
          question.phone_number = number
          expect(question).to be_valid
        end
      end
    end

    context "when phone number is over 15 numbers" do
      it "returns an error" do
        question.phone_number = "123456791123456789"
        expect(question).not_to be_valid

        expect(question.errors[:phone_number]).to include(I18n.t("activemodel.errors.models.question/phone_number.attributes.phone_number.phone_too_long"))
      end
    end

    context "when phone number is 7 numbers or less" do
      it "returns an error" do
        question.phone_number = "1234567"
        expect(question).not_to be_valid

        expect(question.errors[:phone_number]).to include(I18n.t("activemodel.errors.models.question/phone_number.attributes.phone_number.phone_too_short"))
      end
    end

  end
end
