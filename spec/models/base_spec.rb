require "rails_helper"

RSpec.describe Base, type: :model do
  describe ".headers" do
    it "does not add 'X-API-Token' header" do
      expect(described_class.headers.keys).not_to include("X-API-Token")
    end

    context "when auth is required" do
      before do
        allow(Settings.forms_api).to receive(:enabled_auth).and_return(true)
        allow(Settings.forms_api).to receive(:auth_key).and_return("something-secret")
      end

      it "does include 'X-API-Token' header" do
        expect(described_class.headers.keys).to include("X-API-Token")
      end

      it "sets 'X-API-Token' header value to the auth key" do
        expect(described_class.headers["X-API-Token"]).to eq("something-secret")
      end
    end
  end
end
