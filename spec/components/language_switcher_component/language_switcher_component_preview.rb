class LanguageSwitcherComponent::LanguageSwitcherComponentPreview < ViewComponent::Preview
  def default
    render(LanguageSwitcherComponent::View.new)
  end

  def with_languages
    render(LanguageSwitcherComponent::View.new(languages: %w[en cy]))
  end
end
