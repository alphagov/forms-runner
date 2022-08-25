require "rails_helper"

RSpec.describe "Errors", type: :request do
  describe "Page not found" do
    it "returns http code 404" do
      get "/404"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "root path" do
    it "returns http code 404" do
      get "/"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "Internal server error" do
    it "returns http code 500" do
      get "/500"
      expect(response).to have_http_status(:internal_server_error)
    end
  end

  describe "Service unavailable page" do
    it "returns http code 503" do
      stub_const "ENV", ENV.to_h.merge("SERVICE_UNAVAILABLE" => "true")
      get "/"
      expect(response).to have_http_status(:service_unavailable)
    end
  end

  describe "Submission error" do
    let(:form_response_data) do
      {
        id: 2,
        name: "Form name",
        submission_email: "submission@email.com",
        start_page: 1,
      }.to_json
    end

    let(:notify_service) { instance_double(NotifyService) }

    let(:req_headers) do
      {
        "X-API-Token" => ENV["API_KEY"],
        "Accept" => "application/json",
      }
    end

    before do
      ActiveResource::HttpMock.respond_to do |mock|
        mock.get "/api/v1/forms/2", req_headers, form_response_data, 200
      end

      allow(notify_service).to receive(:send_email).and_throw("Oh no!").with(any_args)
      allow(NotifyService).to receive(:new).and_return(notify_service)
    end

    it "returns http code 500" do
      post form_submit_answers_path(form_id: 2)
      expect(response).to have_http_status(:internal_server_error)
    end
  end
end
