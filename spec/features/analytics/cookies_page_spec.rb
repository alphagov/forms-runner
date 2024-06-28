require "rails_helper"

feature "Cookies page", type: :feature do
  before do
    allow(Settings).to receive(:analytics_enabled).and_return(analytics_enabled)
    visit cookies_path
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

      it "does not display the cookie banner" do
        expect(page).not_to have_css(".govuk-cookie-banner", visible: :visible)
      end

      it "displays the cookie consent form" do
        expect(page).to have_css("legend", text: "Do you want to accept analytics cookies?", visible: :visible)
        expect(page).to have_field("Yes", type: :radio, visible: :false)
        expect(page).to have_field("No", type: :radio, visible: :false)
        expect(page).to have_button("Save cookie settings", visible: :visible)
      end

      it "does not display the success message" do
        expect(page).not_to have_text("You’ve set your cookie preferences.")
      end
    end

    context "when the user has rejected cookies" do
      before do
        within_fieldset "Do you want to accept analytics cookies?" do
          choose "No"
        end

        click_button "Save cookie settings"
      end

      it "does not load in Google Analytics" do
        expect(page).not_to have_selector('script[src*="googletagmanager"]', visible: :hidden)
      end

      it "does not display the cookie banner" do
        expect(page).not_to have_css(".govuk-cookie-banner", visible: :visible)
      end

      it "displays the cookie consent form" do
        expect(page).to have_css("legend", text: "Do you want to accept analytics cookies?", visible: :visible)
        expect(page).to have_field("Yes", visible: false)
        expect(page).to have_checked_field("No", visible: false)
        expect(page).to have_button("Save cookie settings")
      end

      it "displays the success message" do
        expect(page).to have_text("You’ve set your cookie preferences.")
      end
    end

    context "when the user has accepted cookies" do
      before do
        within_fieldset "Do you want to accept analytics cookies?" do
          choose "Yes"
        end

        click_button "Save cookie settings"
      end

      it "loads in Google Analytics" do
        expect(page).to have_selector('script[src*="googletagmanager"]', visible: :hidden)
      end

      it "does not display the cookie banner" do
        expect(page).not_to have_css(".govuk-cookie-banner", visible: :visible)
      end

      it "displays the cookie consent form" do
        expect(page).to have_css("legend", text: "Do you want to accept analytics cookies?", visible: :visible)
        expect(page).to have_checked_field("Yes", visible: false)
        expect(page).to have_field("No", visible: false)
        expect(page).to have_button("Save cookie settings")
      end

      it "displays the success message" do
        expect(page).to have_text("You’ve set your cookie preferences.")
      end
    end
  end
end
