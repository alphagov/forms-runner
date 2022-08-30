require "rails_helper"

RSpec.describe Form, type: :model do
  let(:response_data) { { id: 1, name: "form name", submission_email: "user@example.com", start_page: 1 }.to_json }

  let(:pages_data) do
    [
      { id: 9, next_page: 10, answer_type: "date", question_text: "Question one" },
      { id: 10, answer_type: "address", question_text: "Question two" },
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
      mock.get "/api/v1/forms/1", req_headers, response_data, 200
      mock.get "/api/v1/forms/1/pages", req_headers, pages_data, 200
    end
  end

  it "returns a simple form" do
    expect(described_class.find(1)).to have_attributes(id: 1, name: "form name", submission_email: "user@example.com")
  end

  describe "Getting the pages for a form" do
    it "returns the pages for a form" do
      pages = described_class.find(1).pages
      expect(pages.length).to eq(2)
      expect(pages[0]).to have_attributes(id: 9, next_page: 10, answer_type: "date", question_text: "Question one")
      expect(pages[1]).to have_attributes(id: 10, answer_type: "address", question_text: "Question two")
    end
  end
end
