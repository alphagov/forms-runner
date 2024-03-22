require "rails_helper"

RSpec.describe SessionHasher do
  let(:request) { instance_double(ActionDispatch::Request) }
  let(:session) { instance_double(ActionDispatch::Request::Session, id: session_id) }
  let(:session_id) { "123" }
  let(:hashed_session_id) { Digest::SHA256.hexdigest(session_id) }

  before do
    allow(request).to receive(:session).and_return(session)
  end

  describe "#request_to_session_hash" do
    subject(:request_to_session_hash) { described_class.new(request).request_to_session_hash }

    context "when the session has an ID" do
      it "returns a SHA256 digest of the session id" do
        expect(request_to_session_hash).to eq(hashed_session_id)
      end
    end

    context "when the session does not have an ID" do
      let(:session_id) { nil }

      it "returns nil" do
        expect(request_to_session_hash).to be_nil
      end
    end

    context "when there is no session" do
      let(:session) { nil }

      it "returns nil" do
        expect(request_to_session_hash).to be_nil
      end
    end
  end
end
