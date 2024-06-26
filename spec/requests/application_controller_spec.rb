require "rails_helper"

RSpec.describe ApplicationController, type: :request do
  subject(:application_controller) { described_class.new }

  describe "Accessibility statement" do
    it "returns http code 200" do
      get accessibility_statement_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "Cookies page" do
    it "returns http code 200" do
      get cookies_path
      expect(response).to have_http_status(:ok)
    end
  end

  context "when setting logging context" do
    before do
      get root_path, headers: { "HTTP_X_AMZN_TRACE_ID": "Root=1-63441c4a-abcdef012345678912345678" }
    end

    it "adds the trace ID to the logging context" do
      expect(logging_context).to include(trace_id: "Root=1-63441c4a-abcdef012345678912345678")
    end

    it "adds the host to the logging context" do
      expect(logging_context).to include(host: "www.example.com")
    end

    it "adds the request_id to the logging context" do
      expect(logging_context).to include(:request_id)
    end

    it "adds the session_id_has to the logging context" do
      expect(logging_context).to include(:session_id_hash)
    end
  end

  context "when the service is in maintenance mode" do
    let(:bypass_ips) { " " }
    let(:expect_response_to_redirect) { true }
    let(:user_ip) { "192.0.0.2" }

    before do
      allow(Settings.maintenance_mode).to receive_messages(enabled: true, bypass_ips:)

      get cookies_path, headers: { "HTTP_X_FORWARDED_FOR": user_ip }
      follow_redirect! if expect_response_to_redirect
    end

    it "returns http code 200" do
      expect(response).to have_http_status(:ok)
    end

    it "renders the maintenance page" do
      expect(response).to render_template("errors/maintenance")
    end

    context "when bypass ip range does not cover the user's ip" do
      let(:bypass_ips) { "192.0.0.0/32, 123.123.123.123/32" }

      it "returns http code 200" do
        expect(response).to have_http_status(:ok)
      end

      it "renders the maintenance page" do
        expect(response).to render_template("errors/maintenance")
      end
    end

    context "when the bypass ip range does include the user's ip" do
      let(:bypass_ips) { "192.0.0.0/29, 123.123.123.123/32" }
      let(:expect_response_to_redirect) { false }

      it "returns http code 200" do
        expect(response).to have_http_status(:ok)
      end

      it "renders the cookie page" do
        expect(response).to render_template("application/cookies")
      end
    end
  end

  describe "#user_ip" do
    [
      ["", nil],
      ["127.0.0.1", "127.0.0.1"],
      ["127.0.0.1, 192.168.0.128", "127.0.0.1"],
      ["185.93.3.65, 15.158.44.215, 10.0.1.94", "185.93.3.65"],
      ["    185.93.3.65, 15.158.44.215, 10.0.1.94", nil],
      ["invalid value, 192.168.0.128", nil],
      ["192.168.0.128.123.2981", nil],
      ["2001:db8::, 2001:db8:3333:4444:CCCC:DDDD:EEEE:FFFF, ::1234:5678", "2001:db8::"],
      [",,,,,,,,,,,,,,,,,,,,,,,,", nil],
    ].each do |value, expected|
      it "returns #{expected.inspect} when given forwarded_for #{value.inspect}" do
        expect(application_controller.user_ip(value)).to eq(expected)
      end
    end
  end

  describe "#up" do
    it "returns http code 200" do
      get rails_health_check_path
      expect(response).to have_http_status(:ok)
    end
  end
end
