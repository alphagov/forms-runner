module AxeFeatureHelpers
  ARIA_ALLOWED_ATTR = "aria-allowed-attr".freeze

  def expect_page_to_have_no_axe_errors(page)
    expect(page).to be_axe_clean.according_to(:wcag2a, :wcag2aa, :wcag21a, :wcag21aa).skipping ARIA_ALLOWED_ATTR
    expect(page).to be_axe_clean.excluding(".govuk-radios__input").checking_only ARIA_ALLOWED_ATTR
  end

  def expect_component_to_have_no_axe_errors(page)
    expect(page).to be_axe_clean.within("#main-content").according_to(:wcag2a, :wcag2aa, :wcag21a, :wcag21aa).skipping ARIA_ALLOWED_ATTR
    expect(page).to be_axe_clean.within("#main-content").excluding(".govuk-radios__input").checking_only ARIA_ALLOWED_ATTR
  end
end

RSpec.configure do |config|
  config.include AxeFeatureHelpers, type: :feature
end
