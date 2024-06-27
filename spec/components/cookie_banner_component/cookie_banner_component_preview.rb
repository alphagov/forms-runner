class CookieBannerComponent::CookieBannerComponentPreview < ViewComponent::Preview
  def default
    render(CookieBannerComponent::View.new)
  end
end
