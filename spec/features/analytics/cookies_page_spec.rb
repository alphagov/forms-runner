require "rails_helper"

feature "Cookies page" do
  scenario "with analytics turned off" do
    when_analytics_is_not_enabled
    when_i_visit_the_cookies_page
    it_does_not_load_google_analytics
    it_does_not_display_the_cookie_banner
    it_does_not_display_the_cookie_consent_form
    it_does_not_display_the_non_js_message
  end

  scenario "when the user has not set a cookie consent status" do
    when_analytics_is_enabled
    when_i_visit_the_cookies_page
    it_does_not_load_google_analytics
    it_does_not_display_the_cookie_banner
    it_displays_the_cookie_consent_form
    it_does_not_display_the_success_message
    it_does_not_display_the_non_js_message
  end

  scenario "when the user rejects cookies" do
    when_analytics_is_enabled
    when_i_visit_the_cookies_page
    then_i_reject_analytics_cookies
    it_does_not_load_google_analytics
    it_does_not_display_the_cookie_banner
    it_displays_the_cookie_consent_form
    it_checks_the_no_radio_button_by_default
    it_displays_the_success_message
    it_does_not_display_the_non_js_message
  end

  scenario "when the user accepts cookies" do
    when_analytics_is_enabled
    when_i_visit_the_cookies_page
    then_i_accept_analytics_cookies
    it_loads_google_analytics
    it_does_not_display_the_cookie_banner
    it_displays_the_cookie_consent_form
    it_checks_the_yes_radio_button_by_default
    it_displays_the_success_message
    it_does_not_display_the_non_js_message
  end

  scenario "without javascript enabled", driver: :rack_test do
    when_analytics_is_enabled
    when_i_visit_the_cookies_page
    it_does_not_load_google_analytics
    it_does_not_display_the_cookie_banner
    it_does_not_display_the_cookie_consent_form
    it_does_not_display_the_success_message
    it_displays_the_non_js_message
  end

private

  def when_analytics_is_enabled
    allow(Settings).to receive(:analytics_enabled).and_return(true)
  end

  def when_analytics_is_not_enabled
    allow(Settings).to receive(:analytics_enabled).and_return(false)
  end

  def when_i_visit_the_cookies_page
    visit cookies_path
  end

  def then_i_accept_analytics_cookies
    within_fieldset "Do you want to accept analytics cookies?" do
      choose "Yes"
    end

    click_button "Save cookie settings"
  end

  def then_i_reject_analytics_cookies
    within_fieldset "Do you want to accept analytics cookies?" do
      choose "No"
    end

    click_button "Save cookie settings"
  end

  def it_loads_google_analytics
    expect(page).to have_selector('script[src*="googletagmanager"]', visible: :hidden)
  end

  def it_does_not_load_google_analytics
    expect(page).not_to have_selector('script[src*="googletagmanager"]', visible: :hidden)
  end

  def it_does_not_display_the_cookie_banner
    expect(page).not_to have_css(".govuk-cookie-banner", visible: :visible)
  end

  def it_displays_the_cookie_consent_form
    expect(page).to have_css("legend", text: "Do you want to accept analytics cookies?", visible: :visible)
    expect(page).to have_field("Yes", type: :radio, visible: :hidden)
    expect(page).to have_field("No", type: :radio, visible: :hidden)
    expect(page).to have_button("Save cookie settings", visible: :visible)
  end

  def it_checks_the_no_radio_button_by_default
    expect(page).to have_checked_field("No", visible: :hidden)
  end

  def it_checks_the_yes_radio_button_by_default
    expect(page).to have_checked_field("Yes", visible: :hidden)
  end

  def it_does_not_display_the_cookie_consent_form
    expect(page).not_to have_css("form", visible: :visible)
  end

  def it_displays_the_success_message
    expect(page).to have_text("You’ve set your cookie preferences.")
  end

  def it_does_not_display_the_success_message
    expect(page).not_to have_text("You’ve set your cookie preferences.")
  end

  def it_displays_the_non_js_message
    expect(page).to have_text("We cannot change your cookie settings at the moment because JavaScript is not running in your browser.")
  end

  def it_does_not_display_the_non_js_message
    expect(page).not_to have_text("We cannot change your cookie settings at the moment because JavaScript is not running in your browser.")
  end
end
