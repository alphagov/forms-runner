require "rails_helper"

RSpec.describe "Form controller", type: :request do
  let(:form_response_data) do
    {
      id: 2,
      name: "Form name",
      submission_email: "submission@email.com",
      start_page: "1",
    }.to_json
  end

  let(:pages_data) do
    [
      {
        id: 1,
        question_text: "Question one",
        question_short_name: nil,
        answer_type: "date",
        next: "2",
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
      mock.get "/api/v1/forms/2", req_headers, form_response_data, 200
      mock.get "/api/v1/forms/2/pages", req_headers, pages_data, 200
    end
  end

  describe "#show" do
    before do
      get form_path(id: 2)
    end

    context "when the form has a start page" do
      it "Redirects to the first page" do
        expect(response).to redirect_to(form_page_path(2, 1))
      end
    end

    context "when the form has no start page" do
      let(:form_response_data) do
        {
          id: 2,
          name: "Form name",
          submission_email: "submission@email.com",
          start_page: nil,
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
end
