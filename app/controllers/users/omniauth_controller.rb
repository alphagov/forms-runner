# app/controllers/users/omniauth_controller.rb
module Users
  class OmniauthController < ApplicationController
    def callback
      omniauth_info = request.env["omniauth.auth"]["info"]
      if omniauth_info
        puts "USER IS LOGGED IN"
      else
        puts "USER IS NOT LOGGED IN"
      end
    end

    def failure
      puts "FAILURE"
    end
  end
end
