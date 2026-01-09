require "rails_helper"

RSpec.describe LanguageSwitcherComponent::View, type: :component do
  include Rails.application.routes.url_helpers

  let(:languages) { [] }

  before do
    with_request_url "/current-page" do
      render_inline(described_class.new(languages:))
    end
  end

  context "with no languages provided" do
    it "does not render" do
      expect(page).not_to have_css("nav")
    end
  end

  context "with one language provided" do
    let(:languages) { %w[en] }

    it "does not render" do
      expect(page).not_to have_css("nav")
    end
  end

  context "with 2 or more languages provided" do
    let(:languages) { %w[en cy] }

    it "renders the component" do
      expect(page).to have_css("nav[aria-label=\"#{I18n.t('language_switcher.nav_label')}\"]")
    end

    it "adds unlinked text for the current language" do
      expect(page).to have_text("English")
      expect(page).not_to have_link("English")
    end

    it "adds links for all other languages with the correct attributes" do
      expect(page).to have_link("Cymraeg", href: "/current-page?locale=cy")
      expect(page).to have_css("a[lang=\"cy\"][hreflang=\"cy\"][rel=\"alternate\"]", text: "Cymraeg")
    end
  end
end
