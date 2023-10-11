require "rails_helper"

RSpec.describe Forms::BaseController, type: :request do
  let(:timestamp_of_request) { Time.utc(2022, 12, 14, 10, 0o0, 0o0) }

  let(:form_response_data) do
    build(:form, :with_support,
          id: 2,
          live_at:,
          start_page:,
          privacy_policy_url: "http://www.example.gov.uk/privacy_policy",
          what_happens_next_text: "Good things come to those that wait",
          declaration_text: "agree to the declaration",
          pages: pages_data)
  end
  let(:start_page) { 1 }
  let(:live_at) { "2022-08-18 09:16:50 +0100" }

  let(:no_data_found_response) do
    {
      "error": "not_found",
    }
  end

  let(:pages_data) do
    [
      (build :page,
             id: 1,
             next_page: 2,
             answer_type: "text",
             answer_settings: { input_type: "single_line" }
      ),
      (build :page,
             id: 2,
             answer_type: "text",
             answer_settings: { input_type: "single_line" }
      ),
    ]
  end

  let(:req_headers) do
    {
      "X-API-Token" => Settings.forms_api.auth_key,
      "Accept" => "application/json",
    }
  end

  let(:api_url_suffix) { "/live" }

  before do
    ActiveResource::HttpMock.respond_to do |mock|
      allow(LogEventService).to receive(:log_form_start).at_least(:once)
      mock.get "/api/v1/forms/2#{api_url_suffix}", req_headers, form_response_data.to_json, 200
      mock.get "/api/v1/forms/9999#{api_url_suffix}", req_headers, no_data_found_response, 404
    end
  end

  describe "#redirect_to_user_friendly_url" do
    before do
      get form_id_path(mode: "form", form_id: 2)
    end

    context "when the form exists and has a start page" do
      let(:start_page) { 1 }

      it "redirects to the friendly URL start page" do
        expect(response).to redirect_to(form_page_path("form", 2, form_response_data.form_slug, 1))
      end
    end

    context "when the form exists and has no start page" do
      let(:start_page) { nil }

      it "Returns a 404" do
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "#error_repeat_submission" do
    before do
      ActiveResource::HttpMock.respond_to do |mock|
        allow(LogEventService).to receive(:log_form_start).at_least(:once)
        mock.get "/api/v1/forms/2/live", req_headers, form_response_data.to_json, 200
      end

      get error_repeat_submission_path(mode: "form", form_id: 2, form_slug: form_response_data.form_slug)
    end

    it "renders the page with a link back to the form start page" do
      expect(response.body).to include(form_page_path("form", 2, form_response_data.form_slug, 1))
    end
  end

  describe "#show" do
    context "with preview mode on" do
      context "with a draft form" do
        let(:api_url_suffix) { "/draft" }

        context "when a form exists" do
          before do
            travel_to timestamp_of_request do
              get form_path(mode: "preview-draft", form_id: 2, form_slug: form_response_data.form_slug)
            end
          end

          context "when the form has a start page" do
            it "Redirects to the first page" do
              expect(response).to redirect_to(form_page_path("preview-draft", 2, form_response_data.form_slug, 1))
            end

            it "does not log the form_visit event" do
              expect(LogEventService).not_to have_received(:log_form_start)
            end
          end

          context "when the form has no start page" do
            let(:start_page) { nil }

            it "returns 404" do
              expect(response).to have_http_status(:not_found)
            end
          end

          it "Returns the correct X-Robots-Tag header" do
            expect(response.headers["X-Robots-Tag"]).to eq("noindex, nofollow")
          end

          describe "Privacy page" do
            it "returns http code 200" do
              get form_privacy_path(mode: "preview-draft", form_id: 2, form_slug: "form-name")
              expect(response).to have_http_status(:ok)
            end

            it "contains link to data controller's privacy policy" do
              get form_privacy_path(mode: "preview-draft", form_id: 2, form_slug: "form-name")
              expect(response.body).to include("http://www.example.gov.uk/privacy_policy")
            end
          end
        end

        context "when a form doesn't exists" do
          before do
            get form_path(mode: "preview-draft", form_id: 9999, form_slug: "form-name-1")
          end

          it "Render the not found page" do
            expect(response.body).to include(I18n.t("not_found.title"))
          end

          it "returns 404" do
            expect(response).to have_http_status(:not_found)
          end
        end

        context "when the form has no start page" do
          let(:start_page) { nil }

          before do
            get form_path(mode: "preview-draft", form_id: 9999, form_slug: "form-name")
          end

          it "Render the not found page" do
            expect(response.body).to include(I18n.t("not_found.title"))
          end

          it "returns 404" do
            expect(response).to have_http_status(:not_found)
          end
        end
      end

      context "with a live form" do
        let(:api_url_suffix) { "/live" }

        context "when a form exists" do
          before do
            travel_to timestamp_of_request do
              get form_path(mode: "preview-live", form_id: 2, form_slug: form_response_data.form_slug)
            end
          end

          context "when the form has a start page" do
            it "Redirects to the first page" do
              expect(response).to redirect_to(form_page_path("preview-live", 2, form_response_data.form_slug, 1))
            end

            it "does not log the form_visit event" do
              expect(LogEventService).not_to have_received(:log_form_start)
            end
          end

          context "when the form has no start page" do
            let(:start_page) { nil }

            it "returns 404" do
              expect(response).to have_http_status(:not_found)
            end
          end

          it "Returns the correct X-Robots-Tag header" do
            expect(response.headers["X-Robots-Tag"]).to eq("noindex, nofollow")
          end

          describe "Privacy page" do
            it "returns http code 200" do
              get form_privacy_path(mode: "preview-live", form_id: 2, form_slug: form_response_data.form_slug)
              expect(response).to have_http_status(:ok)
            end

            it "contains link to data controller's privacy policy" do
              get form_privacy_path(mode: "preview-live", form_id: 2, form_slug: form_response_data.form_slug)
              expect(response.body).to include("http://www.example.gov.uk/privacy_policy")
            end
          end
        end

        context "when a form doesn't exists" do
          before do
            get form_path(mode: "preview-live", form_id: 9999, form_slug: "form-name-1")
          end

          it "Render the not found page" do
            expect(response.body).to include(I18n.t("not_found.title"))
          end

          it "returns 404" do
            expect(response).to have_http_status(:not_found)
          end
        end

        context "when the form has no start page" do
          let(:start_page) { nil }

          before do
            get form_path(mode: "preview-live", form_id: 9999, form_slug: "form-name")
          end

          it "Render the not found page" do
            expect(response.body).to include(I18n.t("not_found.title"))
          end

          it "returns 404" do
            expect(response).to have_http_status(:not_found)
          end
        end
      end
    end

    context "with preview mode off" do
      context "when a form is live" do
        context "when a form exists" do
          before do
            travel_to timestamp_of_request do
              get form_path(mode: "form", form_id: 2, form_slug: form_response_data.form_slug)
            end
          end

          context "when the form has a start page" do
            it "Redirects to the first page" do
              expect(response).to redirect_to(form_page_path("form", 2, form_response_data.form_slug, 1))
            end

            it "Logs the form_visit event" do
              expect(LogEventService).to have_received(:log_form_start).with(an_instance_of(Context), an_instance_of(ActionDispatch::Request))
            end
          end

          context "when the form has no start page" do
            let(:start_page) { nil }

            it "returns 404" do
              expect(response).to have_http_status(:not_found)
            end
          end

          it "Returns the correct X-Robots-Tag header" do
            expect(response.headers["X-Robots-Tag"]).to eq("noindex, nofollow")
          end
        end

        context "when a live form doesn't exist" do
          before do
            get form_path(mode: "form", form_id: 9999, form_slug: "form-name")
          end

          it "returns 404" do
            expect(response).to have_http_status(:not_found)
          end

          it "Render the not found page" do
            expect(response.body).to include(I18n.t("not_found.title"))
          end
        end
      end
    end
  end
end
