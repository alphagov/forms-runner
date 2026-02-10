require "rails_helper"

RSpec.describe Users::OmniauthController, type: :controller do
  describe "GET #callback" do
    let(:email) { "person@example.gov.uk" }

    before do
      request.env["omniauth.auth"] = { "info" => { "email" => email } }
    end

    context "when previous form context exists in session" do
      before do
        session[:govuk_one_login_last_mode] = "form"
        session[:govuk_one_login_last_form_id] = "2"
        session[:govuk_one_login_last_form_slug] = "test-form"
        session[:govuk_one_login_last_locale] = "en"

        get :callback
      end

      it "stores the signed in email in session" do
        expect(session[:govuk_one_login_email]).to eq(email)
      end

      it "redirects back to the previous form check your answers page" do
        expect(response).to redirect_to(check_your_answers_path(mode: "form", form_id: "2", form_slug: "test-form", locale: "en"))
      end
    end

    context "when previous form context exists and return path is email confirmation" do
      before do
        session[:govuk_one_login_last_mode] = "form"
        session[:govuk_one_login_last_form_id] = "2"
        session[:govuk_one_login_last_form_slug] = "test-form"
        session[:govuk_one_login_last_locale] = "en"
        session[:govuk_one_login_return_to] = "email_confirmation"

        get :callback
      end

      it "redirects back to the previous form email confirmation page" do
        expect(response).to redirect_to(email_confirmation_path(mode: "form", form_id: "2", form_slug: "test-form", locale: "en"))
      end
    end

    context "when previous form context is missing" do
      before do
        get :callback
      end

      it "renders a plain text response" do
        expect(response.body).to eq("#{email} is signed in")
      end
    end
  end
end
