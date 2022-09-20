module Forms
  class SubmittedController < FormController
    def submitted
      @current_context = current_context
    end
  end
end
