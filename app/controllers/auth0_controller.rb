# This is only used to authenticate access to the Mission Control Jobs route
class Auth0Controller < ApplicationController
  require "auth0"

  def callback
    auth_info = request.env["omniauth.auth"]
    user_id = auth_info["uid"]

    # Verify that the user has the required role assigned in Auth0
    return redirect_to error_401_path unless user_has_role(user_id)

    session[:userinfo] = auth_info["extra"]["raw_info"]

    redirect_to "/jobs"
  end

  def failure
    error_msg = request.params["message"]
    Rails.logger.info("Auth0 authentication failure: #{error_msg}")
    redirect_to error_401_path
  end

  # this isn't linked to from anywhere
  def logout
    session.delete(:userinfo)
    redirect_to logout_url, allow_other_host: true
  end

private

  def logout_url
    request_params = {
      returnTo: mission_control_jobs_url,
      client_id: Settings.auth0.client_id,
    }

    URI::HTTPS.build(host: Settings.auth0.domain, path: "/v2/logout", query: request_params.to_query).to_s
  end

  def user_has_role(user_id)
    roles = auth0_client.get_user_roles(user_id)
    roles.any? && roles.pick("id").include?(Settings.auth0.mission_control_role_id)
  end

  def auth0_client
    Auth0Client.new(
      client_id: Settings.auth0.client_id,
      client_secret: Settings.auth0.client_secret,
      domain: Settings.auth0.domain,
    )
  end
end
