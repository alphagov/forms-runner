require "rails_helper"

RSpec.describe "Application pages", type: :request do
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
end
