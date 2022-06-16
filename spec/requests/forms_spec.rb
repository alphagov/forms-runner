require "rails_helper"

RSpec.describe "Form controller", type: :request do
  let(:form_response_data) do
    {
      id: 2,
      name: "Form name",
      submission_email: "submission@email.com",
      start_page: 1
    }.to_json
  end

  before do
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get "/api/v1/forms/2", {}, form_response_data, 200
    end
  end

  describe "#show" do
    before do
      get form_path(id: 2)
    end

    it "Redirects to the first page" do
      expect(response).to redirect_to(form_page_path(form_id: 2, id: 1))
    end
  end
end
