require "rails_helper"

RSpec.describe Forms::BaseController, type: :request do
  let(:timestamp_of_request) { Time.utc(2022, 12, 14, 10, 0o0, 0o0) }

  let(:form_response_data) do
    build(
      :v2_form_document,
      :with_support,
      id: 2,
      live_at:,
      start_page:,
      privacy_policy_url: "http://www.example.gov.uk/privacy_policy",
      what_happens_next_markdown: "Good things come to those that wait",
      declaration_text: "agree to the declaration",
      steps: steps_data,
      language:,
    )
  end
  let(:start_page) { 1 }
  let(:live_at) { "2022-08-18 09:16:50 +0100" }
  let(:language) { "en" }

  let(:no_data_found_response) do
    {
      "error": "not_found",
    }
  end

  let(:steps_data) do
    [
      (attributes_for :v2_question_page_step,
                      id: 1,
                      next_page: 2,
                      answer_type: "text",
                      answer_settings: { input_type: "single_line" }
      ),
      (attributes_for :v2_question_page_step,
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

  let(:output) { StringIO.new }
  let(:logger) do
    ApplicationLogger.new(output).tap do |logger|
      logger.formatter = JsonLogFormatter.new
    end
  end

  before do
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get "/api/v2/forms/2#{api_url_suffix}", req_headers, form_response_data.to_json, 200
      mock.get "/api/v2/forms/9999#{api_url_suffix}", req_headers, no_data_found_response, 404
    end
  end

  describe "logging" do
    let(:form_id) { 2 }
    let(:trace_id) { "Root=1-63441c4a-abcdef012345678912345678" }
    let(:request_id) { "a-request-id" }

    before do
      Rails.logger.broadcast_to logger

      get form_id_path(mode: "form", form_id:), headers: {
        "HTTP_X_AMZN_TRACE_ID": trace_id,
        "X-REQUEST-ID": request_id,
      }
    end

    after do
      Rails.logger.stop_broadcasting_to logger
    end

    it "logs when the form is visited" do
      expect(log_lines[0]["event"]).to eq("form_visit")
    end

    it "includes the form_name on log lines" do
      expect(log_lines[0]["form_name"]).to eq(form_response_data.name)
    end

    it "includes the form_id on log lines" do
      expect(log_lines[0]["form_id"]).to eq(form_id.to_s)
    end

    it "includes preview bool on log lines" do
      expect(log_lines[0]["preview"]).to eq("false")
    end

    it "includes the trace ID on log lines" do
      expect(log_lines[0]["trace_id"]).to eq(trace_id)
    end

    it "includes the request_host on log lines" do
      expect(log_lines[0]["request_host"]).to eq("www.example.com")
    end

    it "includes the request_id on log lines" do
      expect(log_lines[0]["request_id"]).to eq(request_id)
    end
  end

  describe "#redirect_to_user_friendly_url" do
    before do
      get form_id_path(mode: "form", form_id: 2)
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
        mock.get "/api/v2/forms/2/live", req_headers, form_response_data.to_json, 200
      end

      get error_repeat_submission_path(mode: "form", form_id: 2, form_slug: form_response_data.form_slug)
    end

    it "renders the page with a link back to the form start page" do
      expect(response.body).to include(form_page_path(mode: "form", form_id: 2, form_slug: form_response_data.form_slug, page_slug: 1))
    end
  end

  describe "#show" do
    context "with preview mode on" do
      context "with a draft form" do
        let(:api_url_suffix) { "/draft" }

        context "when a form exists" do
          before do
            allow(LogEventService).to receive(:log_form_start)
            travel_to timestamp_of_request do
              get form_path(mode: "preview-draft", form_id: 2, form_slug: form_response_data.form_slug)
            end
          end

          context "when the form has a start page" do
            it "Redirects to the first page" do
              expect(response).to redirect_to(form_page_path(mode: "preview-draft", form_id: 2, form_slug: form_response_data.form_slug, page_slug: 1))
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
            expect(response.body).to include(I18n.t("errors.not_found.title"))
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
            expect(response.body).to include(I18n.t("errors.not_found.title"))
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
            allow(LogEventService).to receive(:log_form_start)
            travel_to timestamp_of_request do
              get form_path(mode: "preview-live", form_id: 2, form_slug: form_response_data.form_slug)
            end
          end

          context "when the form has a start page" do
            it "Redirects to the first page" do
              expect(response).to redirect_to(form_page_path(mode: "preview-live", form_id: 2, form_slug: form_response_data.form_slug, page_slug: 1))
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
            expect(response.body).to include(I18n.t("errors.not_found.title"))
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
            expect(response.body).to include(I18n.t("errors.not_found.title"))
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
            allow(LogEventService).to receive(:log_form_start)
            travel_to timestamp_of_request do
              get form_path(mode: "form", form_id: 2, form_slug: form_response_data.form_slug)
            end
          end

          context "when the form has a start page" do
            it "Redirects to the first page" do
              expect(response).to redirect_to(form_page_path(mode: "form", form_id: 2, form_slug: form_response_data.form_slug, page_slug: 1))
            end

            it "Logs the form_visit event" do
              expect(LogEventService).to have_received(:log_form_start)
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
            expect(response.body).to include(I18n.t("errors.not_found.title"))
          end
        end
      end

      context "when the form is archived" do
        before do
          ActiveResource::HttpMock.respond_to do |mock|
            mock.get "/api/v2/forms/2/live", req_headers, nil, 404
            mock.get "/api/v2/forms/2/archived", req_headers, form_response_data.to_json, 200
          end

          get form_path(mode: "form", form_id: 2, form_slug: form_response_data.form_slug)
        end

        it "Renders the form archived page" do
          expect(response.body).to include(I18n.t("form.archived.title"))
        end
      end
    end
  end

  describe "locale" do
    context "when getting a form page that exists" do
      before do
        get form_page_path(mode: "form", form_id: 2, form_slug: form_response_data.form_slug, page_slug: 1)
      end

      context "when the form is English" do
        it "renders content in English" do
          expect(response.body).to include(I18n.t("support_details.get_help_with_this_form"))
        end
      end

      context "when the form is Welsh" do
        let(:language) { "cy" }

        it "renders content in Welsh" do
          expect(response.body).to include(I18n.t("support_details.get_help_with_this_form", locale: :cy))
        end
      end

      context "when the language attribute is not set for the form" do
        let(:form_response_data) do
          form_document = build(
            :v2_form_document,
            :with_support,
            id: 2,
            live_at:,
            start_page:,
            privacy_policy_url: "http://www.example.gov.uk/privacy_policy",
            what_happens_next_markdown: "Good things come to those that wait",
            declaration_text: "agree to the declaration",
            steps: steps_data,
          )
          form_document.delete_field(:language)
          form_document
        end

        it "renders content in English" do
          expect(response.body).to include(I18n.t("support_details.get_help_with_this_form"))
        end
      end
    end

    context "when getting a form page that doesn't exist" do
      before do
        get form_page_path(mode: "form", form_id: 2, form_slug: form_response_data.form_slug, page_slug: 42)
      end

      context "when the form is English" do
        it "returns 404" do
          expect(response).to have_http_status(:not_found)
        end

        it "renders the error page in English" do
          expect(response.body).to include(I18n.t("errors.not_found.title"))
        end
      end

      context "when the form is Welsh" do
        let(:language) { "cy" }

        it "returns 404" do
          expect(response).to have_http_status(:not_found)
        end

        it "renders the error page in Welsh" do
          expect(response.body).to include(I18n.t("errors.not_found.title", locale: :cy))
        end
      end
    end
  end

  def log_lines
    output.string.split("\n").map { |line| JSON.parse(line) }
  end
end
