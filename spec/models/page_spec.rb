require "rails_helper"

RSpec.describe Page, type: :model do
  let(:response_data) do
    {
      id: 1,
      question_text: "Question text",
      answer_type: "date",
    }.to_json
  end

  let(:req_headers) do
    {
      "X-API-Token" => ENV["API_KEY"],
      "Accept" => "application/json",
    }
  end

  before do
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get "/api/v1/forms/2/pages/1", req_headers, response_data, 200
    end
  end

  it "returns the page for a form" do
    expect(described_class.find(1, params: { form_id: 2 })).to have_attributes(id: 1, question_text: "Question text", answer_type: "date")
  end
end
