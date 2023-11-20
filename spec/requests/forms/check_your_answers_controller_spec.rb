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

  let(:email_confirmation_form) do
    { send_confirmation: "send_email",
      confirmation_email_address: Faker::Internet.email,
      confirmation_email_reference: "confirmation-email-ref",
      notify_reference: "for-my-ref" }
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

  let(:live_at) { "2022-08-18 09:16:50 +0100" }

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

  let(:api_url_suffix) { "/live" }

  let(:frozen_time) { Time.zone.local(2023, 3, 13, 9, 47, 57) }

  let(:repeat_form_submission) { false }

  before do
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get "/api/v1/forms/2#{api_url_suffix}", req_headers, form_data.to_json, 200
    end

    allow(Context).to receive(:new).and_wrap_original do |original_method, *args|
      context_spy = original_method.call(form: args[0][:form], store:)
      allow(context_spy).to receive(:form_submitted?).and_return(repeat_form_submission)
      context_spy
    end
  end

  shared_examples "for submission reference" do
    uuid = /[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}/

    let(:notify_reference) { assigns[:email_confirmation_form].notify_reference }
    let(:confirmation_email_reference) { assigns[:email_confirmation_form].confirmation_email_reference }

    it "generates a random submission notification reference" do
      expect(notify_reference)
        .to match(uuid).and end_with("-submission-email")
    end

    it "generates a random email confirmation notification reference" do
      expect(confirmation_email_reference)
        .to match(uuid).and end_with("-confirmation-email")
    end

    it "generates a different string for all notification references" do
      expect(notify_reference).not_to eq confirmation_email_reference
    end

    it "includes a common identifier in all notification references" do
      uuid_in = ->(str) { uuid.match(str).to_s }

      expect(uuid_in[notify_reference]).to eq uuid_in[confirmation_email_reference]
    end
  end

  describe "#show" do
    context "with preview mode on" do
      let(:api_url_suffix) { "/draft" }

      context "without any questions answered" do
        let(:store) do
          {
            answers: {},
          }
        end

        it "redirects to first incomplete page of form" do
          get check_your_answers_path(mode: "preview-draft", form_id: 2, form_slug: form_data.form_slug)
          expect(response.status).to eq(302)
          expect(response.location).to eq(form_page_url(2, form_data.form_slug, 1))
        end
      end

      context "with all questions answered and valid" do
        before do
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

        include_examples "for submission reference"
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
        let(:store) do
          {
            answers: {},
          }
        end

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

        include_examples "for submission reference"
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

  describe "#submit_answers" do
    before do
      allow(LogEventService).to receive(:log_submit).at_least(:once)
    end

    context "with preview mode on" do
      before do
        travel_to frozen_time do
          post form_submit_answers_path("preview-live", 2, "form-name", 1), params: { email_confirmation_form: }
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
        expect(mail.to).to eq [form_data.submission_email]

        expected_personalisation = {
          title: form_data.name,
          text_input: ".*",
          submission_time: "9:47am",
          submission_date: "13 March 2023",
          test: "yes",
          not_test: "no",
        }

        expect(mail.body.raw_source).to match(expected_personalisation.to_s)

        expect(mail.govuk_notify_reference).to eq "for-my-ref"
      end
    end

    context "with preview mode off" do
      before do
        travel_to frozen_time do
          post form_submit_answers_path("form", 2, "form-name", 1), params: { email_confirmation_form: }
        end
      end

      it "redirects to confirmation page" do
        expect(response).to redirect_to(form_submitted_path)
      end

      it "Logs the submit event with service logger" do
        expect(LogEventService).to have_received(:log_submit).with(instance_of(Context), instance_of(ActionDispatch::Request), requested_email_confirmation: true)
      end

      it "emails the form submission" do
        deliveries = ActionMailer::Base.deliveries
        expect(deliveries.length).to eq 1

        mail = deliveries[0]
        expect(mail.to).to eq [form_data.submission_email]

        expected_personalisation = {
          title: form_data.name,
          text_input: ".*",
          submission_time: "9:47am",
          submission_date: "13 March 2023",
          test: "no",
          not_test: "yes",
        }

        expect(mail.body.raw_source).to match(expected_personalisation.to_s)
      end

      context "when user has opted into the confirmation email" do
        it "Logs the submit event with requested_email_confirmation set to true" do
          expect(LogEventService).to have_received(:log_submit).with(instance_of(Context), instance_of(ActionDispatch::Request), requested_email_confirmation: true)
        end
      end

      context "when user has not opted into the confirmation email" do
        let(:email_confirmation_form) do
          { send_confirmation: "skip_confirmation",
            confirmation_email_address: nil,
            notify_reference: "for-my-ref" }
        end

        it "Logs the submit event with requested_email_confirmation set to false" do
          expect(LogEventService).to have_received(:log_submit).with(instance_of(Context), instance_of(ActionDispatch::Request), requested_email_confirmation: false)
        end
      end
    end

    context "when answers have already been submitted" do
      let(:repeat_form_submission) { true }

      before do
        post form_submit_answers_path("form", 2, "form-name", 1), params: { email_confirmation_form: }
      end

      it "redirects to repeat submission error page" do
        expect(response).to redirect_to(error_repeat_submission_path(2))
      end
    end

    context "when the confirmation email flag is enabled", feature_email_confirmations_enabled: true do
      context "when user has not specified whether they want a confirmation email" do
        let(:email_confirmation_form) { { send_confirmation: nil } }

        before do
          post form_submit_answers_path("form", 2, "form-name", 1), params: { email_confirmation_form: }
        end

        it "return 422 error code" do
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "renders the check your answers page" do
          expect(response).to render_template("forms/check_your_answers/show")
        end

        it "generates a new submission reference" do
          expect(assigns[:email_confirmation_form].notify_reference).not_to eq email_confirmation_form[:notify_reference]
          expect(assigns[:email_confirmation_form].confirmation_email_reference).not_to eq email_confirmation_form[:confirmation_email_reference]
        end

        include_examples "for submission reference"
      end

      context "when user has not specified the confirmation email address" do
        let(:email_confirmation_form) { { send_confirmation: "send_email", confirmation_email_address: nil } }

        before do
          post form_submit_answers_path("form", 2, "form-name", 1), params: { email_confirmation_form: }
        end

        it "return 422 error code" do
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "renders the check your answers page" do
          expect(response).to render_template("forms/check_your_answers/show")
        end

        it "generates a new submission reference" do
          expect(assigns[:email_confirmation_form].notify_reference).not_to eq email_confirmation_form[:notify_reference]
          expect(assigns[:email_confirmation_form].confirmation_email_reference).not_to eq email_confirmation_form[:confirmation_email_reference]
        end

        include_examples "for submission reference"
      end

      context "when user has not requested a confirmation email" do
        let(:email_confirmation_form) { { send_confirmation: "skip_confirmation", confirmation_email_address: nil, notify_reference: "for-my-ref" } }

        before do
          post form_submit_answers_path("form", 2, "form-name", 1), params: { email_confirmation_form: }
        end

        it "redirects to confirmation page" do
          expect(response).to redirect_to(form_submitted_path)
        end
      end

      context "when user has requested a confirmation email" do
        let(:email_confirmation_form) do
          { send_confirmation: "send_email",
            confirmation_email_address: Faker::Internet.email,
            confirmation_email_reference: "confirmation-email-ref",
            notify_reference: "for-my-ref" }
        end

        before do
          travel_to timestamp_of_request do
            post form_submit_answers_path("form", 2, "form-name", 1), params: { email_confirmation_form: }
          end
        end

        it "redirects to confirmation page" do
          expect(response).to redirect_to(form_submitted_path)
        end

        it "sends a confirmation email" do
          deliveries = ActionMailer::Base.deliveries
          expect(deliveries.length).to eq 2

          mail = deliveries[1]
          expect(mail.to).to eq([email_confirmation_form[:confirmation_email_address]])

          expected_personalisation = {
            title: form_data.name,
            what_happens_next_text: form_data.what_happens_next,
            support_contact_details: contact_support_details_format,
            submission_time: "10:00am",
            submission_date: "14 December 2022",
            test: "no",
          }

          expect(mail.body.raw_source).to include(expected_personalisation.to_s)

          expect(mail.govuk_notify_reference).to eq "confirmation-email-ref"
        end
      end
    end
  end

private

  def contact_support_details_format
    phone_number = "#{form_data.support_phone}\n\n[#{I18n.t('support_details.call_charges')}]()"
    email = "[#{form_data.support_email}](mailto:#{form_data.support_email})"
    online = "[#{form_data.support_url_text}](#{form_data.support_url})"
    [phone_number, email, online].compact_blank.join("\n\n")
  end
end
