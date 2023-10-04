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
    }
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

  let(:frozen_time) { Time.zone.local(2023, 3, 13, 9, 47, 57) }

  let(:repeat_form_submission) { false }

  before do
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get "/api/v1/forms/2/live", req_headers, form_response_data.to_json, 200
    end

    allow(LogEventService).to receive(:log_submit).at_least(:once)

    allow(Context).to receive(:new).and_wrap_original do |original_method, *args|
      context_spy = original_method.call(form: args[0][:form], store:)
      allow(context_spy).to receive(:form_submitted?).and_return(repeat_form_submission)
      context_spy
    end
  end

  describe "#submit_answers" do
    context "with preview mode on" do
      before do
        travel_to frozen_time do
          post form_submit_answers_path("preview-live", 2, "form-name", 1)
        end
      end

      it "redirects to confirmation page" do
        expect(response).to redirect_to(form_submitted_path)
      end

      it "does not log the form_submission event" do
        expect(LogEventService).not_to have_received(:log_submit)
      end

      it "emails the form submission" do
        deliveries = ActionMailer::Base.deliveries
        expect(deliveries.length).to eq 1

        mail = deliveries[0]
        expect(mail.to).to eq [form_response_data[:submission_email]]

        expected_personalisation = {
          title: "Form name",
          text_input: ".*",
          submission_time: "09:47:57",
          submission_date: "13 March 2023",
          test: "yes",
          not_test: "no",
        }

        expect(mail.body.raw_source).to match(expected_personalisation.to_s)
      end
    end

    context "with preview mode off" do
      before do
        travel_to frozen_time do
          post form_submit_answers_path("form", 2, "form-name", 1)
        end
      end

      it "redirects to confirmation page" do
        expect(response).to redirect_to(form_submitted_path)
      end

      it "Logs the submit event with service logger" do
        expect(LogEventService).to have_received(:log_submit).with(instance_of(Context), instance_of(ActionDispatch::Request))
      end

      it "emails the form submission" do
        deliveries = ActionMailer::Base.deliveries
        expect(deliveries.length).to eq 1

        mail = deliveries[0]
        expect(mail.to).to eq [form_response_data[:submission_email]]

        expected_personalisation = {
          title: "Form name",
          text_input: ".*",
          submission_time: "09:47:57",
          submission_date: "13 March 2023",
          test: "no",
          not_test: "yes",
        }

        expect(mail.body.raw_source).to match(expected_personalisation.to_s)
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
