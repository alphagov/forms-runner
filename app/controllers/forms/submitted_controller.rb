module Forms
  class SubmittedController < BaseController
    def submitted
      session.delete(:datetime_started) if session[:datetime_started].present?
      @current_context = current_context
    end
  end
end
