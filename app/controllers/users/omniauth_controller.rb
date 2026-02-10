require "debug"
module Users
  class OmniauthController < ApplicationController
    def callback
      omniauth_info = request.env["omniauth.auth"]["info"]
      session[:govuk_one_login_email] = omniauth_info["email"]

      if previous_form_context_present?
        redirect_to check_your_answers_path(
          mode: session[:govuk_one_login_last_mode],
          form_id: session[:govuk_one_login_last_form_id],
          form_slug: session[:govuk_one_login_last_form_slug],
          locale: session[:govuk_one_login_last_locale],
        )
      else
        render plain: "#{omniauth_info['email']} is signed in"
      end
    end

    def failure
      render plain: env.inspect
    end

  private

    def previous_form_context_present?
      session[:govuk_one_login_last_mode].present? &&
        session[:govuk_one_login_last_form_id].present? &&
        session[:govuk_one_login_last_form_slug].present?
    end
  end
end
