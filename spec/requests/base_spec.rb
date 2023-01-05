require "rails_helper"

RSpec.describe "Base controller", type: :request do
  let(:timestamp_of_request) { Time.utc(2022, 12, 14, 10, 0o0, 0o0) }
  let(:form_response_data) do
    {
      id: 2,
      name: "Form name",
      form_slug: "form-name",
      submission_email: "submission@email.com",
      start_page: "1",
      live_at: "2022-08-18 09:16:50 +0100",
      privacy_policy_url: "http://www.example.gov.uk/privacy_policy",
      what_happens_next_text: "Good things come to those that wait",
      declaration_text: "agree to the declaration",
      support_email: "help@example.gov.uk",
      support_phone: "Call 01610123456\n\nThis line is only open on Tuesdays.",
      support_url: "https://example.gov.uk/contact",
      support_url_text: "Contact us",
    }.to_json
  end

  let(:no_data_found_response) do
    {
      "error": "not_found",
    }
  end

  let(:pages_data) do
    [
      {
        id: 1,
        question_text: "Question one",
        question_short_name: nil,
        answer_type: "date",
        next_page: 2,
        is_optional: nil,
      },
      {
        id: 2,
        question_text: "Question two",
        question_short_name: nil,
        answer_type: "date",
        is_optional: nil,
      },
    ].to_json
  end

  let(:session) do
    {
      answers: {
        "1": { date_day: 1, date_month: 2, date_year: 2022 },
        "2": { date_day: 1, date_month: 2, date_year: 2022 },
      },
    }
  end

  let(:req_headers) do
    {
      "X-API-Token" => ENV["API_KEY"],
      "Accept" => "application/json",
    }
  end

  before do
    ActiveResource::HttpMock.respond_to do |mock|
      allow(EventLogger).to receive(:log).at_least(:once)
      mock.get "/api/v1/forms/2", req_headers, form_response_data, 200
      mock.get "/api/v1/forms/2/pages", req_headers, pages_data, 200
      mock.get "/api/v1/forms/9999", req_headers, no_data_found_response, 404
    end
  end

  describe "#redirect_to_user_friendly_url" do
    context "when the form exists and has a start page" do
      before do
        get form_id_path(mode: "form", form_id: 2)
      end

      it "redirects to the friendly URL start page" do
        expect(response).to redirect_to(form_page_path("form", 2, "form-name", 1))
      end
    end

    context "when the form exists and has no start page" do
      let(:form_response_data) do
        {
          id: 2,
          name: "Form name",
          form_slug: "form-name",
          submission_email: "submission@email.com",
          live_at: "2022-08-18 09:16:50 +0100",
          start_page: nil,
          privacy_policy_url: "http://www.example.gov.uk/privacy_policy",
          support_email: "help@example.gov.uk",
          support_phone: "Call 01610123456\n\nThis line is only open on Tuesdays.",
          support_url: "https://example.gov.uk/contact",
          support_url_text: "Contact us",
        }.to_json
      end

      before do
        get form_id_path(mode: "form", form_id: 2)
      end

      it "Redirects to the form page that includes the form slug" do
        expect(response.status).to eq(404)
      end
    end
  end

  describe "#show" do
    context "with preview mode on" do
      context "when a form exists" do
        before do
          travel_to timestamp_of_request do
            get form_path(mode: "preview-form", form_id: 2, form_slug: "form-name")
          end
        end

        context "when the form has a start page" do
          it "Redirects to the first page" do
            expect(response).to redirect_to(form_page_path("preview-form", 2, "form-name", 1))
          end

          it "does not log the form_visit event" do
            expect(EventLogger).not_to have_received(:log)
          end
        end

        context "when the form has no start page" do
          let(:form_response_data) do
            {
              id: 2,
              name: "Form name",
              form_slug: "form-name",
              submission_email: "submission@email.com",
              start_page: nil,
              privacy_policy_url: "http://www.example.gov.uk/privacy_policy",
            }.to_json
          end

          it "returns 404" do
            expect(response.status).to eq(404)
          end
        end

        it "Returns the correct X-Robots-Tag header" do
          expect(response.headers["X-Robots-Tag"]).to eq("noindex, nofollow")
        end

        describe "Privacy page" do
          it "returns http code 200" do
            get form_privacy_path(mode: "form", form_id: 2, form_slug: "form-name")
            expect(response).to have_http_status(:ok)
          end

          it "contains link to data controller's privacy policy" do
            get form_privacy_path(mode: "form", form_id: 2, form_slug: "form-name")
            expect(response.body).to include("http://www.example.gov.uk/privacy_policy")
          end
        end

        context "and a form has a live_at value in the future" do
          let(:form_response_data) do
            {
              id: 2,
              name: "Form name",
              form_slug: "form-name",
              submission_email: "submission@email.com",
              live_at: "2023-01-01 09:00:00 +0100",
              start_page: "1",
              privacy_policy_url: "http://www.example.gov.uk/privacy_policy",
            }.to_json
          end

          it "does not return 404" do
            expect(response.status).not_to eq(404)
          end
        end
      end

      context "when a form doesn't exists" do
        before do
          get form_path(mode: "preview-form", form_id: 9999, form_slug: "form-name-1")
        end

        it "Render the not found page" do
          expect(response.body).to include(I18n.t("not_found.title"))
        end

        it "returns 404" do
          expect(response.status).to eq(404)
        end
      end

      context "when the form has no start page" do
        let(:form_response_data) do
          {
            id: 2,
            name: "Form name",
            form_slug: "form-name",
            submission_email: "submission@email.com",
            start_page: nil,
            privacy_policy_url: "http://www.example.gov.uk/privacy_policy",
            what_happens_next_text: "Good things come to those that wait",
            declaration_text: "agree to the declaration",
            support_email: "help@example.gov.uk",
            support_phone: "Call 01610123456\n\nThis line is only open on Tuesdays.",
            support_url: "https://example.gov.uk/contact",
            support_url_text: "Contact us",
          }.to_json
        end

        before do
          get form_path(mode: "preview-form", form_id: 9999, form_slug: "form-name")
        end

        it "Render the not found page" do
          expect(response.body).to include(I18n.t("not_found.title"))
        end

        it "returns 404" do
          expect(response.status).to eq(404)
        end
      end
    end

    context "with preview mode off" do
      context "when a form is live" do
        context "when a form exists" do
          before do
            travel_to timestamp_of_request do
              get form_path(mode: "form", form_id: 2, form_slug: "form-name")
            end
          end

          context "when the form has a start page" do
            it "Redirects to the first page" do
              expect(response).to redirect_to(form_page_path("form", 2, "form-name", 1))
            end

            it "Logs the form_visit event" do
              expect(EventLogger).to have_received(:log).with("form_visit", { form: "Form name", method: "GET", url: "http://www.example.com/form/2/form-name" })
            end
          end

          context "when the form has no start page" do
            let(:form_response_data) do
              {
                id: 2,
                name: "Form name",
                form_slug: "form-name",
                submission_email: "submission@email.com",
                start_page: nil,
                live_at: "2022-08-18 09:16:50 +0100",
                privacy_policy_url: "http://www.example.gov.uk/privacy_policy",
                support_email: "help@example.gov.uk",
                support_phone: "Call 01610123456\n\nThis line is only open on Tuesdays.",
                support_url: "https://example.gov.uk/contact",
                support_url_text: "Contact us",
              }.to_json
            end

            it "returns 404" do
              expect(response.status).to eq(404)
            end
          end

          it "Returns the correct X-Robots-Tag header" do
            expect(response.headers["X-Robots-Tag"]).to eq("noindex, nofollow")
          end
        end

        context "when a form doesn't exist" do
          before do
            get form_path(mode: "form", form_id: 9999, form_slug: "form-name")
          end

          it "returns 404" do
            expect(response.status).to eq(404)
          end

          it "Render the not found page" do
            expect(response.body).to include(I18n.t("not_found.title"))
          end
        end
      end

      context "and a form has a live_at value in the future" do
        let(:form_response_data) do
          {
            id: 2,
            name: "Form name",
            form_slug: "form-name",
            submission_email: "submission@email.com",
            live_at: "2023-08-18 09:16:50 +0100",
            start_page: nil,
            privacy_policy_url: "http://www.example.gov.uk/privacy_policy",
            support_email: "help@example.gov.uk",
            support_phone: "Call 01610123456\n\nThis line is only open on Tuesdays.",
            support_url: "https://example.gov.uk/contact",
            support_url_text: "Contact us",
          }.to_json
        end

        before do
          travel_to timestamp_of_request do
            get form_path(mode: "form", form_id: 2, form_slug: "form-name")
          end
        end

        it "returns 404" do
          expect(response.status).to eq(404)
        end
      end
    end
  end

  describe "#submit_answers" do
    context "with preview mode on" do
      before do
        post form_submit_answers_path("preview-form", 2, "form-name", 1)
      end

      it "does not log the form_submission event" do
        expect(EventLogger).not_to have_received(:log)
      end
    end

    context "with preview mode off" do
      before do
        post form_submit_answers_path("form", 2, "form-name", 1)
      end

      it "Logs the form_submission event" do
        expect(EventLogger).to have_received(:log).with("form_submission", { form: "Form name", method: "POST", url: "http://www.example.com/form/2/form-name/submit-answers.1" })
      end
    end
  end
end
