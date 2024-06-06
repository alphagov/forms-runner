require "rails_helper"

RSpec.describe Forms::SubmittedController, type: :request do
  let(:context) { Flow::Context.new(form: form_data, store:) }

  let(:form_data) do
    build(:form, :with_support,
          id: 2,
          start_page: 1,
          privacy_policy_url: "http://www.example.gov.uk/privacy_policy",
          what_happens_next_markdown: "Your application will be processed within a few days.\n\nContact us if you need to:\n\n-change the details of your application\n-cancel your application",
          declaration_text: "agree to the declaration",
          pages: pages_data)
  end

  let(:pages_data) do
    [
      build(:page,
            id: 1,
            position: 1,
            question_text: "Question one",
            answer_type: "date",
            next_page: 2,
            is_optional: nil),
      build(:page,
            id: 2,
            position: 2,
            question_text: "Question two",
            answer_type: "date",
            is_optional: nil),
    ]
  end

  let(:store) do
    {
      answers: {
        "2" => {
          "1" => {
            "date_year" => "2000",
            "date_month" => "1",
            "date_day" => "1",
          },
          "2" => {
            "date_year" => "2023",
            "date_month" => "6",
            "date_day" => "9",
          },
        },
      },
    }
  end

  let(:req_headers) do
    {
      "X-API-Token" => Settings.forms_api.auth_key,
      "Accept" => "application/json",
    }
  end

  describe "#submitted" do
    before do
      ActiveResource::HttpMock.respond_to do |mock|
        mock.get "/api/v1/forms/2/draft", req_headers, form_data.to_json, 200
      end

      allow(Flow::Context).to receive(:new).and_return(context)
      allow(context).to receive(:clear)

      get form_submitted_path(mode: "preview-draft", form_id: 2, form_slug: form_data.form_slug)
    end

    it "renders the what happens next markdown" do
      expect(response.body).to include(HtmlMarkdownSanitizer.new.render_scrubbed_markdown(form_data.what_happens_next_markdown))
    end

    it "renders the submitted page template" do
      expect(response).to render_template("forms/submitted/submitted")
    end

    it "returns 200" do
      expect(response).to have_http_status(:ok)
    end

    it "clears the context" do
      expect(context).to have_received(:clear)
    end
  end
end
