require "rails_helper"

RSpec.describe Forms::SubmitAnswersController, type: :request do
  let(:form_response_data) do
    {
      id: 2,
      name: "Form name",
      form_slug: "form-name",
      submission_email: "submission@email.com",
      start_page: "1",
      live_at: "2022-08-18 09:16:50 +0100",
      privacy_policy_url: "http://www.example.gov.uk/privacy_policy",
      what_happens_next_text: "Good things come to those that wait",
      declaration_text: "agree to the declaration",
      support_email: "help@example.gov.uk",
      support_phone: "Call 01610123456\n\nThis line is only open on Tuesdays.",
      support_url: "https://example.gov.uk/contact",
      support_url_text: "Contact us",
      pages: pages_data,
    }.to_json
  end

  let(:req_headers) do
    {
      "X-API-Token" => Settings.forms_api.auth_key,
      "Accept" => "application/json",
    }
  end

  let(:pages_data) do
    [
      {
        id: 1,
        question_text: "Question one",
        answer_type: "date",
        next_page: 2,
        is_optional: nil,
      },
      {
        id: 2,
        question_text: "Question two",
        answer_type: "date",
        is_optional: nil,
      },
    ]
  end

  before do
    ActiveResource::HttpMock.respond_to do |mock|
      allow(EventLogger).to receive(:log).at_least(:once)
      mock.get "/api/v1/forms/2/live", req_headers, form_response_data, 200
    end
  end

  describe "#submit_answers" do
    context "with preview mode on" do
      before do
        post form_submit_answers_path("preview-form", 2, "form-name", 1)
      end

      it "does not log the form_submission event" do
        expect(EventLogger).not_to have_received(:log)
      end
    end

    context "with preview mode off" do
      before do
        post form_submit_answers_path("form", 2, "form-name", 1)
      end

      it "Logs the form_submission event" do
        expect(EventLogger).to have_received(:log).with("form_submission", { form: "Form name", method: "POST", url: "http://www.example.com/form/2/form-name/submit-answers.1" })
      end
    end

    context "when session has expired" do
      before do
        travel_to Time.zone.now - 3.days do
          get check_your_answers_path("preview-form", 2, "form-1")
        end
      end

      it "redirects to session expired error page" do
        post form_submit_answers_path("form", 2, "form-name", 1)
        expect(response.status).to eq(302)
        expect(response.location).to eq(error_session_expired_url(2))
      end
    end
  end
end
