require "rails_helper"
require "shared_examples_for_question_models"

RSpec.describe Question::Address, type: :model do
  let(:question) { described_class.new }

  it_behaves_like "a question model"

  context "when an address is empty" do
    it "returns invalid" do
      question.address1 = ""
      question.address2 = ""
      question.town_or_city = ""
      question.county = ""
      question.postcode = ""
      question.validate
      expect(question.errors[:address1]).to include(I18n.t("activemodel.errors.models.question/address.attributes.address1.blank"))
    end

    it "returns \"\" for show_answer" do
      question.address1 = ""
      question.address2 = ""
      question.town_or_city = ""
      question.county = ""
      question.postcode = ""
      expect(question.show_answer).to eq ""
    end
  end

  context "when an address has all mandatory fields filled" do
    it "is valid" do
      question.address1 = "The mews"
      question.address2 = nil
      question.town_or_city = "Leeds"
      question.county = nil
      question.postcode = "LS11AF"
      question.validate
      expect(question).to be_valid
    end

    it "prints correct details" do
      question.address1 = "The mews"
      question.address2 = nil
      question.town_or_city = "Leeds"
      question.county = nil
      question.postcode = "LS11AF"
      expect(question.show_answer).to eq "The mews, Leeds, LS1 1AF"
    end
  end

  context "when given an invalid postcode" do
    it "returns invalid" do
      question.postcode = "jskladjaksd"
      question.validate
      expect(question.errors[:postcode]).to include(I18n.t("activemodel.errors.models.question/address.attributes.postcode.invalid_postcode"))
    end
  end
end
