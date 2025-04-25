require "rails_helper"

RSpec.describe RemoveInput do
  let(:input) { described_class.new({ remove: "yes" }) }

  describe "validations" do
    it "is valid with valid attributes" do
      expect(input).to be_valid
    end

    it "is not valid without remove" do
      input.remove = nil
      expect(input).not_to be_valid
      expect(input.errors[:remove]).to include(I18n.t("activemodel.errors.models.remove_input.attributes.remove.blank"))
    end

    it "is not valid with an invalid remove" do
      input.remove = "invalid"
      expect(input).not_to be_valid
      expect(input.errors[:remove]).to include("is not included in the list")
    end

    it 'is valid with "no" as remove' do
      input.remove = "no"
      expect(input).to be_valid
    end
  end

  describe "#remove?" do
    it 'returns true when remove is "yes"' do
      input = described_class.new(remove: "yes")
      expect(input.remove?).to be true
    end

    it 'returns false when remove is "no"' do
      input = described_class.new(remove: "no")
      expect(input.remove?).to be false
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
