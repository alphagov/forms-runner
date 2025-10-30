require "rails_helper"

RSpec.describe Mode do
  subject(:mode) { described_class.new(mode_string) }

  let(:mode_string) { "form" }

  context "without a mode string" do
    subject(:mode) { described_class.new }

    it "defaults to the live mode" do
      expect(mode).to be_live
    end
  end

  describe "#tag" do
    [
      ["form", :live],
      ["preview-draft", :draft],
      ["preview-archived", :archived],
      ["preview-live", :live],
    ].each do |mode_string, expected_tag|
      context "with the mode string #{mode_string.inspect}" do
        it "returns #{expected_tag.inspect}" do
          mode = described_class.new(mode_string)
          expect(mode.tag).to eq expected_tag
        end
      end
    end
  end
end
