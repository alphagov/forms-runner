require "rails_helper"

RSpec.describe "Page Controller", type: :request do
  let(:form_data) do
    {
      id: 2,
      name: "Form",
      submission_email: "submission@email.com"
    }.to_json
  end

  let(:pages_data) do
    [
      {
        id: 1,
        question_text: "Question one",
        answer_type: "date",
        next: 2
      },
      {
        id: 2,
        question_text: "Question two",
        answer_type: "date"
      }
    ].to_json
  end

  before do
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get "/api/v1/forms/2", {}, form_data, 200
      mock.get "/api/v1/forms/2/pages", {}, pages_data, 200
    end
  end

  describe "#show" do
    it "Returns a 200" do
      get form_page_path(2, 1)
      expect(response.status).to eq(200)
    end

    it "Displays the question text on the page" do
      get form_page_path(2, 1)
      expect(response.body).to include("Question one")
    end

    context "With a page that has a previous page" do
      it "Displays a link to the previous page" do
        get form_page_path(2, 2)
        expect(response.body).to include(form_page_path(2, 1))
      end
    end
  end

  describe "#submit" do
    it "Redirects to the next page" do
      post submit_form_page_path(2, 1)
      expect(response).to redirect_to(form_page_path(2,2))
    end

    context "On the final page" do
      it "Redirects to the check your answers page" do
        post submit_form_page_path(2,2)
        expect(response).to redirect_to(form_check_your_answers_path(2))
      end
    end
  end
end
