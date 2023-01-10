require "rails_helper"

RSpec.describe Question::Address, type: :model do
  subject(:question) { described_class.new({}, options) }

  let(:options) { { is_optional:, answer_settings: } }
  let(:answer_settings) { OpenStruct.new({ input_type: }) }
  let(:input_type) { OpenStruct.new({ international_address:, uk_address: }) }
  let(:is_optional) { false }
  let(:international_address) { "false" }
  let(:uk_address) { "true" }

  it_behaves_like "a question model"

  context "when the address is a UK address" do
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
      let(:is_optional) { true }

      context "when an address is blank" do
        it "returns valid with blank address fields" do
          expect(question).to be_valid
          expect(question.errors[:address1]).not_to include(I18n.t("activemodel.errors.models.question/address.attributes.address1.blank"))
        end

        it "returns valid with empty string address fields" do
          question.address1 = ""
          question.address2 = ""
          question.town_or_city = ""
          question.county = ""
          question.postcode = ""
          expect(question).to be_valid
          expect(question.errors[:address1]).not_to include(I18n.t("activemodel.errors.models.question/address.attributes.address1.blank"))
        end

        it "validates required fields when any fields are filled in" do
          question.address1 = ""
          question.address2 = ""
          question.town_or_city = ""
          question.county = "Lancashire"
          question.postcode = ""
          expect(question).not_to be_valid
          expect(question.errors[:address1]).to include(I18n.t("activemodel.errors.models.question/address.attributes.address1.blank"))
          expect(question.errors[:town_or_city]).to include(I18n.t("activemodel.errors.models.question/address.attributes.town_or_city.blank"))
          expect(question.errors[:postcode]).to include(I18n.t("activemodel.errors.models.question/address.attributes.postcode.blank"))
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

  context "when the address is an international address" do
    let(:international_address) { "true" }

    context "when an address is blank" do
      it "returns invalid with blank address fields" do
        expect(question).not_to be_valid
        expect(question.errors[:street_address]).to include(I18n.t("activemodel.errors.models.question/address.attributes.street_address.blank"))
        expect(question.errors[:country]).to include(I18n.t("activemodel.errors.models.question/address.attributes.country.blank"))
      end

      it "returns invalid with empty string address fields" do
        question.street_address = ""
        question.country = ""
        expect(question).not_to be_valid
        expect(question.errors[:street_address]).to include(I18n.t("activemodel.errors.models.question/address.attributes.street_address.blank"))
        expect(question.errors[:country]).to include(I18n.t("activemodel.errors.models.question/address.attributes.country.blank"))
      end

      it "returns \"\" for show_answer" do
        expect(question.show_answer).to eq ""
      end
    end

    context "when an address has all mandatory fields filled" do
      before do
        question.street_address = "Laskerstraße 5, 10245 Berlin"
        question.country = "Germany"
      end

      it "is valid" do
        expect(question).to be_valid
      end

      it "prints correct details" do
        expect(question.show_answer).to eq "Laskerstraße 5, 10245 Berlin, Germany"
      end
    end

    context "when question is optional" do
      let(:is_optional) { true }

      context "when an address is blank" do
        it "returns valid with blank address fields" do
          expect(question).to be_valid
          expect(question.errors[:street_address]).not_to include(I18n.t("activemodel.errors.models.question/address.attributes.street_address.blank"))
        end

        it "returns valid with empty string address fields" do
          question.street_address = ""
          question.country = ""
          expect(question).to be_valid
          expect(question.errors[:street_address]).not_to include(I18n.t("activemodel.errors.models.question/address.attributes.street_address.blank"))
        end

        it "validates required fields when any fields are filled in" do
          question.street_address = ""
          question.country = "France"
          expect(question).not_to be_valid
          expect(question.errors[:street_address]).to include(I18n.t("activemodel.errors.models.question/address.attributes.street_address.blank"))
        end

        it "returns \"\" for show_answer" do
          expect(question.show_answer).to eq ""
        end
      end

      context "when an address has all mandatory fields filled" do
        before do
          question.street_address = "Laskerstraße 5, 10245 Berlin"
          question.country = "Germany"
        end

        it "is valid" do
          expect(question).to be_valid
        end

        it "prints correct details" do
          expect(question.show_answer).to eq "Laskerstraße 5, 10245 Berlin, Germany"
        end
      end
    end
  end

  describe "#is_international_address?" do
    context "when the question allows both UK and international addresses" do
      let(:international_address) { "true" }
      let(:uk_address) { "true" }

      it "returns true" do
        expect(question.is_international_address?).to be true
      end
    end

    context "when the question allows only international addresses" do
      let(:international_address) { "true" }
      let(:uk_address) { "false" }

      it "returns true" do
        expect(question.is_international_address?).to be true
      end
    end

    context "when the question allows only UK addresses" do
      let(:international_address) { "false" }
      let(:uk_address) { "true" }

      it "returns false" do
        expect(question.is_international_address?).to be false
      end
    end

    context "when the input type is not set" do
      let(:input_type) { nil }

      it "returns false" do
        expect(question.is_international_address?).to be false
      end
    end

    context "when answer_settings is not set" do
      let(:answer_settings) { {} }

      it "returns false" do
        expect(question.is_international_address?).to be false
      end
    end
  end
end
