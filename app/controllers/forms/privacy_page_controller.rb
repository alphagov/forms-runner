module Forms
  class PrivacyPageController < BaseController
    def show
      @privacy_policy_url = current_context.form.privacy_policy_url
    end
  end
end
