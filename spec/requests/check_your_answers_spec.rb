require "rails_helper"

RSpec.describe "Check Your Answers Controller", type: :request do
  let(:form_data) do
    {
      id: 2,
      name: "Form",
      submission_email: "submission@email.com",
      start_page: 1,
      privacy_policy_url: "http://www.example.gov.uk/privacy_policy",
    }.to_json
  end

  let(:pages_data) do
    [
      {
        id: 1,
        question_text: "Question one",
        question_short_name: "one",
        answer_type: "single_line",
        hint_text: "",
        next_page: 2,
      },
      {
        id: 2,
        question_text: "Question two",
        question_short_name: "two",
        hint_text: "Q2 hint text",
        answer_type: "single_line",
      },
    ].to_json
  end

  let(:req_headers) do
    {
      "X-API-Token" => ENV["API_KEY"],
      "Accept" => "application/json",
    }
  end

  before do
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get "/api/v1/forms/2", req_headers, form_data, 200
      mock.get "/api/v1/forms/2/pages", req_headers, pages_data, 200
    end
  end

  describe "#show" do
    context "without any questions answered" do
      it "redirects to first incomplete page of form" do
        get check_your_answers_path(mode: "form", form_id: 2)
        expect(response.status).to eq(302)
        expect(response.location).to eq(form_page_url(2, 1))
      end
    end

    context "with all questions answered and valid" do
      before do
        post save_form_page_path("form", 2, 1), params: { question: { text: "answer text" }, changing_existing_answer: false }
        post save_form_page_path("form", 2, 2), params: { question: { text: "answer text" }, changing_existing_answer: false }
        allow(EventLogger).to receive(:log).at_least(:once)
        get check_your_answers_path(mode: "form", form_id: 2)
      end

      it "returns 200" do
        expect(response.status).to eq(200)
      end

      it "Displays a back link to the last page of the form" do
        expect(response.body).to include(form_page_path("form", 2, 2))
      end

      it "Returns the correct X-Robots-Tag header" do
        expect(response.headers["X-Robots-Tag"]).to eq("noindex, nofollow")
      end

      it "Contains a change link for each page" do
        expect(response.body).to include(form_change_answer_path(2, 1))
        expect(response.body).to include(form_change_answer_path(2, 2))
      end

      it "Logs the form_check_answers event" do
        expect(EventLogger).to have_received(:log).with("form_check_answers", { form: "Form", method: "GET", url: "http://www.example.com/form/2/check_your_answers" })
      end
    end
  end
end
