class AdminController < ApplicationController
  before_action :check_authenticated

private

  def check_authenticated
    redirect_to "/auth/sign-in" unless authenticated?
  end

  def authenticated?
    session[:userinfo].present? && Time.zone.now < session_expiry
  end

  def session_expiry
    raise "Missing expiry on auth session" if session[:userinfo]["exp"].nil?

    Time.zone.at(session[:userinfo]["exp"])
  end
end
