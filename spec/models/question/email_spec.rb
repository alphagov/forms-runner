require "rails_helper"

RSpec.describe Question::Email, type: :model do
  subject(:question) { described_class.new({}, options) }

  let(:options) { { is_optional:, question_text: } }

  let(:is_optional) { false }
  let(:question_text) { Faker::Lorem.question }

  it_behaves_like "a question model"

  shared_examples "format validations" do
    context "when given a valid email address" do
      let(:email) { Faker::Internet.email }

      before do
        question.email = email
      end

      it "is valid" do
        expect(question).to be_valid
      end

      it "is included in show_answer" do
        expect(question.show_answer).to eq email
      end

      it "returns the email address in show_answer_in_csv" do
        expect(question.show_answer_in_csv).to eq(Hash[question_text, email])
      end
    end

    context "when given an invalid email address" do
      it "is invalid" do
        question.email = "no-tld@domain"
        expect(question).not_to be_valid
        expect(question.errors[:email]).to include(I18n.t("activemodel.errors.models.question/email.attributes.email.invalid_email"))
      end
    end
  end

  context "when question is mandatory" do
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

      it "returns a hash with an blank value for show_answer_in_csv" do
        expect(question.show_answer_in_csv).to eq(Hash[question_text, ""])
      end
    end

    include_examples "format validations"
  end

  context "when question is optional" do
    let(:is_optional) { true }

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

    it "returns a hash with an blank value for show_answer_in_csv" do
      expect(question.show_answer_in_csv).to eq(Hash[question_text, ""])
    end

    include_examples "format validations"
  end
end
