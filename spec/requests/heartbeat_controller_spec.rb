require "rails_helper"

describe HeartbeatController do
  describe "#ping" do
    it "returns PONG" do
      get ping_path
      expect(response.body).to eq "PONG"
    end
  end
end
