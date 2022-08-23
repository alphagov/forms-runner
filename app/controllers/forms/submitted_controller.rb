module Forms
  class SubmittedController < FormController
    def submitted
      @privacy_policy_url = current_context.privacy_policy_url
    end
  end
end
