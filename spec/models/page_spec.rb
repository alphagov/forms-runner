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

  context "when answer_settings is not present" do
    it "returns an empty object for answer_settings" do
      expect(described_class.find(1, params: { form_id: 2 })).to have_attributes(answer_settings: {})
    end
  end

  context "when answer_settings is present" do
    let(:response_data) do
      {
        id: 1,
        question_text: "Question text",
        answer_type: "selection",
        answer_settings: { only_one_option: "true" },
      }.to_json
    end

    it "returns an answer settings object for answer_settings" do
      expect(described_class.find(1, params: { form_id: 2 }).answer_settings.attributes).to eq({ "only_one_option" => "true" })
    end
  end
end
