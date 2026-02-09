class AuthController < ApplicationController
  def callback
    # We come here after one login
    # We will need to restore, form_id, mode and form_slug, which we should have saved before sending
    if session["return_to"].present?
      redirect_to session["return_to"]
    end
  end
end
