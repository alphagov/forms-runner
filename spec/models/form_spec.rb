require "rails_helper"

RSpec.describe Form, type: :model do
  let(:response_data) { { person: { "id" => 1, "name" => "form name", "submission_email" => "user@example.com" } }.to_json }

  before do
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get "/api/v1/forms/1", {}, response_data, 200
    end
  end

  it "returns a simple form" do
    expect(described_class.find(1)).to have_attributes(id: 1, name: "form name", submission_email: "user@example.com")
  end
end
