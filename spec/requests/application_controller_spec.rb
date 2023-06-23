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

  context "when the service is in maintenance mode" do
    before do
      allow(Settings.maintenance_mode).to receive(:enabled).and_return(true)
      get cookies_path
      follow_redirect!
    end

    it "returns http code 200" do
      expect(response).to have_http_status(:ok)
    end

    it "renders the maintenance page" do
      expect(response).to render_template("errors/maintenance")
    end
  end
end
