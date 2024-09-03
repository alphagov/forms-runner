require "rails_helper"

RSpec.describe RemoveAnswerInput do
  let(:input) { described_class.new({ remove_answer: "yes" }) }

  describe "validations" do
    it "is valid with valid attributes" do
      expect(input).to be_valid
    end

    it "is not valid without an remove_answer" do
      input.remove_answer = nil
      expect(input).not_to be_valid
      expect(input.errors[:remove_answer]).to include(I18n.t("activemodel.errors.models.remove_answer_input.attributes.remove_answer.blank"))
    end

    it "is not valid with an invalid add_another_answer" do
      input.remove_answer = "invalid"
      expect(input).not_to be_valid
      expect(input.errors[:remove_answer]).to include("is not included in the list")
    end

    it 'is valid with "no" as add_another_answer' do
      input.remove_answer = "no"
      expect(input).to be_valid
    end
  end

  describe "#remove_answer?" do
    it 'returns true when remove_answer is "yes"' do
      input = described_class.new(remove_answer: "yes")
      expect(input.remove_answer?).to be true
    end

    it 'returns false when remove_answer is "no"' do
      input = described_class.new(remove_answer: "no")
      expect(input.remove_answer?).to be false
    end
  end

  describe "#values" do
    it "returns an array of valid values" do
      input = described_class.new
      expect(input.values).to eq(%i[yes no])
    end
  end

  describe "RADIO_OPTIONS" do
    it "has the correct values" do
      expect(described_class::RADIO_OPTIONS).to eq({ yes: "yes", no: "no" })
    end

    it "is frozen" do
      expect(described_class::RADIO_OPTIONS).to be_frozen
    end
  end
end
