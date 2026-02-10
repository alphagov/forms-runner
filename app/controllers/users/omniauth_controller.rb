require "debug"
module Users
  class OmniauthController < ApplicationController
    def callback
      omniauth_info = request.env["omniauth.auth"]["info"]
      render plain: "#{omniauth_info['email']} is signed in"
    end

    def failure
      render plain: env.inspect
    end
  end
end
