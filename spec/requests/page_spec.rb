require "rails_helper"

RSpec.describe "Page Controller", type: :request do
  let(:response_data) do
    {
      question_text: "Question text",
    }.to_json
  end

  before do
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get "/api/v1/forms/2/pages/1", {}, response_data, 200
    end
  end

  describe "#show" do
    before do
      get form_page_path(form_id: 2, id: 1)
    end

    it "Returns a 200" do
      expect(response.status).to eq(200)
    end

    it "Displays the question text on the page" do
      expect(response.body).to include("Question text")
    end
  end
end
