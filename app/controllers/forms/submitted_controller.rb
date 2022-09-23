module Forms
  class SubmittedController < BaseController
    def submitted
      @current_context = current_context
    end
  end
end
