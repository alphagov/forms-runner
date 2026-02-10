require "debug"
module Users
  class OmniauthController < ApplicationController
    def callback
      omniauth_info = request.env["omniauth.auth"]["info"]
      session[:govuk_one_login_email] = omniauth_info["email"]

      if previous_form_context_present?
        redirect_to redirect_path
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

    def redirect_path
      path_args = {
        mode: session[:govuk_one_login_last_mode],
        form_id: session[:govuk_one_login_last_form_id],
        form_slug: session[:govuk_one_login_last_form_slug],
        locale: session[:govuk_one_login_last_locale],
      }

      if session[:govuk_one_login_return_to] == "email_confirmation"
        email_confirmation_path(**path_args)
      else
        check_your_answers_path(**path_args)
      end
    end
  end
end
