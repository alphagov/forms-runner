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
end
