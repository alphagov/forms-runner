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

  let(:req_headers) do
    {
      "X-API-Token" => Settings.forms_api.auth_key,
      "Accept" => "application/json",
    }
  end

  let(:repeat_form_submission) { false }

  before do
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get "/api/v1/forms/2/live", req_headers, form_response_data, 200
    end
    allow(EventLogger).to receive(:log).at_least(:once)
    current_context = instance_double(Context)
    allow(current_context).to receive(:form_submitted?).and_return(repeat_form_submission)
    allow(current_context).to receive(:form_name).and_return("Form name")
    allow(Context).to receive(:new).and_return(current_context)
    allow(FormSubmissionService).to receive(:call).and_return(OpenStruct.new(submit_form_to_processing_team: true))
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

    context "when answers have already been submitted" do
      let(:repeat_form_submission) { true }

      before do
        post form_submit_answers_path("form", 2, "form-name", 1)
      end

      it "redirects to repeat submission error page" do
        expect(response).to redirect_to(error_repeat_submission_path(2))
      end
    end
  end
end
