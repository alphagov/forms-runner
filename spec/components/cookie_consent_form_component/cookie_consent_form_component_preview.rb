# frozen_string_literal: true

class CookieConsentFormComponent::CookieConsentFormComponentPreview < ViewComponent::Preview
  def default
    render(CookieConsentFormComponent::View.new)
  end
end
