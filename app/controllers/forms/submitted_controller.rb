module Forms
  class SubmittedController < BaseController
    def submitted
      current_context.clear
    end
  end
end
