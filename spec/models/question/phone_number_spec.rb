require "rails_helper"
require "shared_examples_for_question_models"

RSpec.describe Question::PhoneNumber, type: :model do
  let(:question) { described_class.new }

  it_behaves_like "a question model"

  context "when a phone number is empty or blank" do
    it "returns invalid" do
      question.phone_number = ""
      question.validate
      expect(question.errors[:phone_number]).to include(I18n.t("activemodel.errors.models.question/phone_number.attributes.phone_number.blank"))
      question.phone_number = nil
      question.validate
      expect(question.errors[:phone_number]).to include(I18n.t("activemodel.errors.models.question/phone_number.attributes.phone_number.blank"))
    end
  end

  context "when a phone number is valid" do
    it "validates correctly" do
      valid_phone_numbers = [
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

      valid_phone_numbers.each do |number|
        question.phone_number = number
        question.validate
        expect(question).to be_valid
      end
    end
  end

  context "when phone number is over 15 numbers" do
    it "returns an error" do
      question.phone_number = "123456791123456789"
      question.validate

      expect(question.errors[:phone_number]).to include(I18n.t("activemodel.errors.models.question/phone_number.attributes.phone_number.phone_too_long"))
    end
  end

  context "when phone number is 7 numbers or less" do
    it "returns an error" do
      question.phone_number = "1234567"
      question.validate

      expect(question.errors[:phone_number]).to include(I18n.t("activemodel.errors.models.question/phone_number.attributes.phone_number.phone_too_short"))
    end
  end
end
