require "rails_helper"

RSpec.describe RemoveFileInput do
  let(:input) { described_class.new({ remove_file: "yes" }) }

  describe "validations" do
    it "is valid with valid attributes" do
      expect(input).to be_valid
    end

    it "is not valid without remove_file" do
      input.remove_file = nil
      expect(input).not_to be_valid
      expect(input.errors[:remove_file]).to include(I18n.t("activemodel.errors.models.remove_file_input.attributes.remove_file.blank"))
    end

    it "is not valid with an invalid remove_file" do
      input.remove_file = "invalid"
      expect(input).not_to be_valid
      expect(input.errors[:remove_file]).to include("is not included in the list")
    end

    it 'is valid with "no" as remove_file' do
      input.remove_file = "no"
      expect(input).to be_valid
    end
  end

  describe "#remove_file?" do
    it 'returns true when remove_file is "yes"' do
      input = described_class.new(remove_file: "yes")
      expect(input.remove_file?).to be true
    end

    it 'returns false when remove_file is "no"' do
      input = described_class.new(remove_file: "no")
      expect(input.remove_file?).to be false
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
