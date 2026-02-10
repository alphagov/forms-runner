require "rails_helper"

RSpec.describe Forms::EmailConfirmationController, type: :request do
  include Capybara::RSpecMatchers

  let(:form_data) do
    build(:v2_form_document, :with_support,
          form_id: 2,
          start_page: 1,
          steps: steps_data)
  end

  let(:steps_data) do
    [
      {
        id: 1,
        position: 1,
        type: "question_page",
        data: {
          answer_type: "text",
          is_optional: nil,
          question_text: "Question one",
        },
      },
    ]
  end

  let(:store) do
    {
      answers: {
        "2" => {
          "1" => { "text" => "Example answer" },
        },
      },
    }
  end

  let(:req_headers) { { "Accept" => "application/json" } }

  before do
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get "/api/v2/forms/2/live", req_headers, form_data.to_json, 200
    end

    allow(Flow::Context).to receive(:new).and_wrap_original do |original_method, *args|
      original_method.call(form: args[0][:form], store:)
    end
  end

  describe "#show" do
    it "returns ok" do
      get email_confirmation_path(mode: "form", form_id: 2, form_slug: form_data.form_slug)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "#save" do
    it "returns 422 when answers-copy option is selected and user is not signed in" do
      post form_save_email_confirmation_path(mode: "form", form_id: 2, form_slug: form_data.form_slug),
           params: {
             email_confirmation_input: {
               send_confirmation: "send_email_with_answers",
               confirmation_email_reference: "reference-id",
             },
           }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include(I18n.t("activemodel.errors.models.email_confirmation_input.attributes.send_confirmation.one_login_required"))
    end

    it "redirects to check your answers when selecting reference-only email" do
      post form_save_email_confirmation_path(mode: "form", form_id: 2, form_slug: form_data.form_slug),
           params: {
             email_confirmation_input: {
               send_confirmation: "send_email",
               confirmation_email_address: "person@example.gov.uk",
               confirmation_email_reference: "reference-id",
             },
           }

      expect(response).to redirect_to(check_your_answers_path(mode: "form", form_id: 2, form_slug: form_data.form_slug))
    end

    it "redirects to check your answers when answers-copy option is selected and user is signed in" do
      allow_any_instance_of(Forms::EmailConfirmationController)
        .to receive(:session)
        .and_wrap_original do |original_method, *args|
          session = original_method.call(*args)
          session[:govuk_one_login_email] = "person@example.gov.uk"
          session
        end

      post form_save_email_confirmation_path(mode: "form", form_id: 2, form_slug: form_data.form_slug),
           params: {
             email_confirmation_input: {
               send_confirmation: "send_email_with_answers",
               confirmation_email_reference: "reference-id",
             },
           }

      expect(response).to redirect_to(check_your_answers_path(mode: "form", form_id: 2, form_slug: form_data.form_slug))
    end
  end
end
