require "rails_helper"

feature "Google analytics", type: :feature do
  before do
    allow(Settings).to receive(:analytics_enabled).and_return(analytics_enabled)
    visit root_path
  end

  context "when the analytics setting is not enabled" do
    let(:analytics_enabled) { false }

    it "does not load in Google Analytics" do
      expect(page).not_to have_selector('script[src*="googletagmanager"]', visible: :hidden)
    end

    it "does not display the cookie banner" do
      expect(page).not_to have_css(".govuk-cookie-banner", visible: :visible)
    end
  end

  context "when the analytics setting is enabled" do
    let(:analytics_enabled) { true }

    context "when the user has not set a cookie consent status" do
      it "does not load in Google Analytics" do
        expect(page).not_to have_selector('script[src*="googletagmanager"]', visible: :hidden)
      end

      it "displays the cookie banner" do
        expect(page).to have_css(".govuk-cookie-banner", visible: :visible)
      end
    end

    context "when the user has rejected cookies" do
      before do
        click_button "Reject analytics cookies"
      end

      it "does not load in Google Analytics" do
        expect(page).not_to have_selector('script[src*="googletagmanager"]', visible: :hidden)
      end

      it "does not display the cookie banner" do
        expect(page).not_to have_css(".govuk-cookie-banner", visible: :visible)
      end
    end

    context "when the user has accepted cookies" do
      before do
        click_button "Accept analytics cookies"
      end

      it "loads in Google Analytics" do
        expect(page).to have_selector('script[src*="googletagmanager"]', visible: :hidden)
      end

      it "does not display the cookie banner" do
        expect(page).not_to have_css(".govuk-cookie-banner", visible: :visible)
      end
    end
  end
end
