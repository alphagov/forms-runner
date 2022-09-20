module Forms
  class PrivacyPageController < FormController
    def show
      @privacy_policy_url = current_context.privacy_policy_url
    end
  end
end
