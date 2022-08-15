require "rails_helper"

RSpec.describe "Form controller", type: :request do
  let(:form_response_data) do
    {
      id: 2,
      name: "Form name",
      submission_email: "submission@email.com",
      start_page: 1,
    }.to_json
  end

  let(:pages_data) do
    [
      {
        id: 1,
        question_text: "Question one",
        question_short_name: nil,
        answer_type: "date",
        next: 2,
      },
      {
        id: 2,
        question_text: "Question two",
        question_short_name: nil,
        answer_type: "date",
      },
    ].to_json
  end

  before do
    ActiveResource::HttpMock.respond_to do |mock|
      allow(EventLogger).to receive(:log).at_least(:once)
      mock.get "/api/v1/forms/2", {}, form_response_data, 200
      mock.get "/api/v1/forms/2/pages", {}, pages_data, 200
      mock.get "/api/v1/forms/2/pages", {}, pages_data, 200
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

      it "Logs the form_visit event" do
        expect(EventLogger).to have_received(:log).with("form_visit", { form: "Form name", method: "GET", url: "http://www.example.com/form/2", user_agent: nil })
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

  describe "#check_your_answers" do
    before do
      get form_check_your_answers_path(2)
    end

    it "Displays a back link to the last page of the form" do
      expect(response.body).to include(form_page_path(2, 2))
    end

    it "Returns the correct X-Robots-Tag header" do
      expect(response.headers["X-Robots-Tag"]).to eq("noindex, nofollow")
    end

    it "Contains a change link for each page" do
      expect(response.body).to include(form_change_answer_path(2, 1))
      expect(response.body).to include(form_change_answer_path(2, 2))
    end

    it "Logs the form_check_answers event" do
      expect(EventLogger).to have_received(:log).with("form_check_answers", { form: "Form name", method: "GET", url: "http://www.example.com/form/2/check_your_answers", user_agent: nil })
    end
  end

  describe "#submit_answers" do
    before do
      post form_submit_answers_path(2, 1)
    end

    it "Logs the form_check_answers event" do
      expect(EventLogger).to have_received(:log).with("form_submission", { form: "Form name", method: "POST", url: "http://www.example.com/form/2/submit_answers.1", user_agent: nil })
    end
  end
end
