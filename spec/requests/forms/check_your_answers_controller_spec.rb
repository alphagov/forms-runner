require "rails_helper"

RSpec.describe Forms::CheckYourAnswersController, type: :request do
  let(:timestamp_of_request) { Time.utc(2022, 12, 14, 10, 0o0, 0o0) }

  let(:form_data) do
    build(:form, :with_support,
          id: 2,
          live_at:,
          start_page: 1,
          privacy_policy_url: "http://www.example.gov.uk/privacy_policy",
          what_happens_next_text: "Good things come to those that wait",
          declaration_text: "agree to the declaration",
          pages: pages_data)
  end

  let(:live_at) { "2022-08-18 09:16:50 +0100" }

  let(:pages_data) do
    [
      (build :page,
             id: 1,
             next_page: 2,
             answer_type: "text",
             answer_settings: { input_type: "single_line" }
      ),
      (build :page,
             id: 2,
             answer_type: "text",
             answer_settings: { input_type: "single_line" }
      ),
    ]
  end

  let(:req_headers) do
    {
      "Accept" => "application/json",
    }
  end

  let(:api_url_suffix) { "/live" }

  before do
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get "/api/v1/forms/2#{api_url_suffix}", req_headers, form_data.to_json, 200
    end
  end

  describe "#show" do
    context "with preview mode on" do
      let(:api_url_suffix) { "/draft" }

      context "without any questions answered" do
        it "redirects to first incomplete page of form" do
          get check_your_answers_path(mode: "preview-draft", form_id: 2, form_slug: form_data.form_slug)
          expect(response.status).to eq(302)
          expect(response.location).to eq(form_page_url(2, form_data.form_slug, 1))
        end
      end

      context "with all questions answered and valid" do
        before do
          post save_form_page_path("preview-draft", 2, form_data.form_slug, 1), params: { question: { text: "answer text" }, changing_existing_answer: false }
          post save_form_page_path("preview-draft", 2, form_data.form_slug, 2), params: { question: { text: "answer text" }, changing_existing_answer: false }
          allow(EventLogger).to receive(:log).at_least(:once)
          get check_your_answers_path(mode: "preview-draft", form_id: 2, form_slug: form_data.form_slug)
        end

        it "returns 200" do
          expect(response.status).to eq(200)
        end

        it "Displays a back link to the last page of the form" do
          expect(response.body).to include(form_page_path("preview-draft", 2, form_data.form_slug, 2))
        end

        it "Returns the correct X-Robots-Tag header" do
          expect(response.headers["X-Robots-Tag"]).to eq("noindex, nofollow")
        end

        it "Contains a change link for each page" do
          expect(response.body).to include(form_change_answer_path(2, form_data.form_slug, 1))
          expect(response.body).to include(form_change_answer_path(2, form_data.form_slug, 2))
        end

        it "does not log the form_check_answers event" do
          expect(EventLogger).not_to have_received(:log)
        end
      end

      context "and a form has a live_at value in the future" do
        let(:live_at) { "2023-01-01 09:00:00 +0100" }

        it "does not return 404" do
          travel_to timestamp_of_request do
            get check_your_answers_path(mode: "preview-draft", form_id: 2, form_slug: form_data.form_slug)
          end

          expect(response.status).not_to eq(404)
        end
      end
    end

    context "with preview mode off" do
      context "without any questions answered" do
        it "redirects to first incomplete page of form" do
          get check_your_answers_path(mode: "form", form_id: 2, form_slug: form_data.form_slug)
          expect(response.status).to eq(302)
          expect(response.location).to eq(form_page_url(2, form_data.form_slug, 1))
        end
      end

      context "with all questions answered and valid" do
        before do
          post save_form_page_path("form", 2, "form-1", 1), params: { question: { text: "answer text" }, changing_existing_answer: false }
          post save_form_page_path("form", 2, "form-1", 2), params: { question: { text: "answer text" }, changing_existing_answer: false }
          allow(EventLogger).to receive(:log_form_event).at_least(:once)
          get check_your_answers_path(mode: "form", form_id: 2, form_slug: form_data.form_slug)
        end

        it "returns 200" do
          expect(response.status).to eq(200)
        end

        it "Displays a back link to the last page of the form" do
          expect(response.body).to include(form_page_path("form", 2, form_data.form_slug, 2))
        end

        it "Returns the correct X-Robots-Tag header" do
          expect(response.headers["X-Robots-Tag"]).to eq("noindex, nofollow")
        end

        it "Contains a change link for each page" do
          expect(response.body).to include(form_change_answer_path(2, form_data.form_slug, 1))
          expect(response.body).to include(form_change_answer_path(2, form_data.form_slug, 2))
        end

        it "Logs the form_check_answers event" do
          expect(EventLogger).to have_received(:log_form_event).with(instance_of(Context), instance_of(ActionDispatch::Request), "check_answers")
        end
      end

      context "and a form has a live_at value in the future" do
        let(:live_at) { "2023-01-01 09:00:00 +0100" }

        it "returns 404" do
          travel_to timestamp_of_request do
            get form_path(mode: "form", form_id: 2, form_slug: form_data.form_slug)
          end
          get check_your_answers_path(mode: "form", form_id: 2, form_slug: form_data.form_slug)
        end
      end
    end
  end
end
