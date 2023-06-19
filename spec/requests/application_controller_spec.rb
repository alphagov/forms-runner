require "rails_helper"

RSpec.describe ApplicationController, type: :request do
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

  context "when the service is unavailable" do
    before do
      allow(Settings.maintenance_mode).to receive(:enabled).and_return(true)
      get root_path
    end

    it "returns http code 503" do
      expect(response).to have_http_status(:service_unavailable)
    end

    it "renders the service unavailable page" do
      expect(response).to render_template("errors/service_unavailable")
    end
  end
end
