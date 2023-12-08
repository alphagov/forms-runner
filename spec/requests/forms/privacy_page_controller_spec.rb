require "rails_helper"

RSpec.describe Forms::PrivacyPageController, type: :request do
  let(:form_data) do
    build(:form, :with_support,
          id: 2,
          start_page: 1,
          privacy_policy_url: "http://www.example.gov.uk/privacy_policy",
          what_happens_next_markdown: "Good things come to those that wait",
          declaration_text: "agree to the declaration",
          pages: pages_data)
  end

  let(:pages_data) do
    [
      {
        id: 1,
        position: 1,
        question_text: "Question one",
        answer_type: "date",
        next_page: 2,
        is_optional: nil,
      },
      {
        id: 2,
        position: 2,
        question_text: "Question two",
        answer_type: "date",
        is_optional: nil,
      },
    ]
  end

  let(:req_headers) do
    {
      "X-API-Token" => Settings.forms_api.auth_key,
      "Accept" => "application/json",
    }
  end

  describe "#show" do
    before do
      ActiveResource::HttpMock.respond_to do |mock|
        mock.get "/api/v1/forms/2/draft", req_headers, form_data.to_json, 200
      end

      get form_privacy_path(mode: "preview-draft", form_id: 2, form_slug: form_data.form_slug)
    end

    it "includes the privacy policy URL" do
      expect(response.body).to include(form_data.privacy_policy_url)
    end

    it "renders the show privacy page template" do
      expect(response).to render_template("forms/privacy_page/show")
    end

    it "returns 200" do
      expect(response).to have_http_status(:ok)
    end
  end
end
