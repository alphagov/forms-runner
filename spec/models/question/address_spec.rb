require "rails_helper"

RSpec.describe Question::Address, type: :model do
  let(:question) { described_class.new }

  it_behaves_like "a question model"

  context "when an address is blank" do
    it "returns invalid with blank address fields" do
      expect(question).not_to be_valid
      expect(question.errors[:address1]).to include(I18n.t("activemodel.errors.models.question/address.attributes.address1.blank"))
    end

    it "returns invalid with empty string address fields" do
      question.address1 = ""
      question.address2 = ""
      question.town_or_city = ""
      question.county = ""
      question.postcode = ""
      expect(question).not_to be_valid
      expect(question.errors[:address1]).to include(I18n.t("activemodel.errors.models.question/address.attributes.address1.blank"))
    end

    it "returns \"\" for show_answer" do
      expect(question.show_answer).to eq ""
    end
  end

  context "when an address has all mandatory fields filled" do
    before do
      question.address1 = "The mews"
      question.address2 = nil
      question.town_or_city = "Leeds"
      question.county = nil
      question.postcode = "LS11AF"
    end

    it "is valid" do
      expect(question).to be_valid
    end

    it "prints correct details" do
      expect(question.show_answer).to eq "The mews, Leeds, LS1 1AF"
    end
  end

  context "when given an invalid postcode" do
    it "returns invalid" do
      question.postcode = "jskladjaksd"
      expect(question).not_to be_valid
      expect(question.errors[:postcode]).to include(I18n.t("activemodel.errors.models.question/address.attributes.postcode.invalid_postcode"))
    end
  end

  context "when question is optional" do
    let(:question) { described_class.new({}, { is_optional: true }) }

    context "when an address is blank" do
      it "returns invalid with blank address fields" do
        expect(question).to be_valid
        expect(question.errors[:address1]).not_to include(I18n.t("activemodel.errors.models.question/address.attributes.address1.blank"))
      end

      it "returns invalid with empty string address fields" do
        question.address1 = ""
        question.address2 = ""
        question.town_or_city = ""
        question.county = ""
        question.postcode = ""
        expect(question).to be_valid
        expect(question.errors[:address1]).not_to include(I18n.t("activemodel.errors.models.question/address.attributes.address1.blank"))
      end

      it "returns \"\" for show_answer" do
        expect(question.show_answer).to eq ""
      end
    end

    context "when an address has all mandatory fields filled" do
      before do
        question.address1 = "The mews"
        question.address2 = nil
        question.town_or_city = "Leeds"
        question.county = nil
        question.postcode = "LS11AF"
      end

      it "is valid" do
        expect(question).to be_valid
      end

      it "prints correct details" do
        expect(question.show_answer).to eq "The mews, Leeds, LS1 1AF"
      end
    end

    context "when given an invalid postcode" do
      it "returns invalid" do
        question.postcode = "jskladjaksd"
        expect(question).not_to be_valid
        expect(question.errors[:postcode]).to include(I18n.t("activemodel.errors.models.question/address.attributes.postcode.invalid_postcode"))
      end
    end
  end
end
