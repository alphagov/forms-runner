require "rails_helper"

RSpec.describe ErrorsController, type: :request do
  describe "Page not found" do
    it "returns http code 404" do
      get error_404_path
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "root path" do
    it "returns http code 404" do
      get root_path
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "random non-exist path" do
    it "returns http code 404" do
      get "/random/string/"
      expect(response).to have_http_status(:not_found)
    end

    it "renders the not found template" do
      get "/random/string/"
      expect(response.body).to include(I18n.t("not_found.title"))
    end
  end

  describe "Internal server error" do
    it "returns http code 500" do
      get error_500_path
      expect(response).to have_http_status(:internal_server_error)
    end
  end

  describe "Submission error" do
    let(:form_response_data) do
      {
        id: 2,
        name: "Form name",
        form_slug: "form-name",
        live_at: "2022-08-18 09:16:50 +0100",
        submission_email: "submission@email.com",
        start_page: 1,
      }.to_json
    end

    let(:form_submission_service) { instance_double(FormSubmissionService) }

    let(:req_headers) do
      {
        "Accept" => "application/json",
      }
    end

    before do
      ActiveResource::HttpMock.respond_to do |mock|
        mock.get "/api/v1/forms/2/live", req_headers, form_response_data, 200
      end

      allow(form_submission_service).to receive(:submit_form_to_processing_team).and_throw("Oh no!").with(any_args)
      allow(FormSubmissionService).to receive(:new).and_return(form_submission_service)
    end

    it "returns http code 500" do
      post form_submit_answers_path(mode: "form", form_id: 2, form_slug: "form-name")
      expect(response).to have_http_status(:internal_server_error)
    end
  end

  describe "Maintenance" do
    before { get maintenance_page_path }

    it "returns http code 200" do
      expect(response).to have_http_status(:ok)
    end

    it "renders the maintenance page" do
      expect(response).to have_rendered("errors/maintenance")
    end
  end
end
