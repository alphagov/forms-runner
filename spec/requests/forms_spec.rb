require "rails_helper"

RSpec.describe "Form controller", type: :request do
  let(:form_response_data) do
    {
      id: 2,
      name: "Form name",
      submission_email: "submission@email.com",
      start_page: "1",
      privacy_policy_url: "http://www.example.gov.uk/privacy_policy",
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
      },
      {
        id: 2,
        question_text: "Question two",
        question_short_name: nil,
        answer_type: "date",
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

  describe "#show" do
    context "when a form exists" do
      before do
        get form_path(mode: "form", id: 2)
      end

      context "when the form has a start page" do
        it "Redirects to the first page" do
          expect(response).to redirect_to(form_page_path("form", 2, 1))
        end

        it "Logs the form_visit event" do
          expect(EventLogger).to have_received(:log).with("form_visit", { form: "Form name", method: "GET", url: "http://www.example.com/form/2" })
        end
      end

      context "when the form has no start page" do
        let(:form_response_data) do
          {
            id: 2,
            name: "Form name",
            submission_email: "submission@email.com",
            start_page: nil,
            privacy_policy_url: "http://www.example.gov.uk/privacy_policy",
          }.to_json
        end

        it "Displays the form show page" do
          expect(response.status).to eq(200)
          expect(response.body).to include("Form name")
        end
      end

      it "Returns the correct X-Robots-Tag header" do
        expect(response.headers["X-Robots-Tag"]).to eq("noindex, nofollow")
      end
    end

    context "when a form doesn't exists" do
      before do
        get form_path(mode: "form", id: 9999)
      end

      it "Render the not found page" do
        expect(response.body).to include(I18n.t("not_found.title"))
      end

      it "returns 404" do
        expect(response.status).to eq(404)
      end
    end
  end

  describe "#submit_answers" do
    before do
      post form_submit_answers_path("form", 2, 1)
    end

    it "Logs the form_submission event" do
      expect(EventLogger).to have_received(:log).with("form_submission", { form: "Form name", method: "POST", url: "http://www.example.com/form/2/submit_answers.1" })
    end
  end
end
