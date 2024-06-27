require "rails_helper"

RSpec.describe CookieBannerComponent::View, type: :component do
  include Rails.application.routes.url_helpers

  before do
    render_inline(described_class.new)
  end

  it "has a heading" do
    expect(page).to have_text(I18n.t("cookie_banner.heading"))
  end

  it "has text explaining what it's for" do
    expect(page).to have_text(I18n.t("cookie_banner.content"))
  end

  it "has accept and reject buttons" do
    expect(page).to have_text(I18n.t("cookie_banner.accept"))
    expect(page).to have_text(I18n.t("cookie_banner.reject"))
  end

  it "has a link to the cookies page" do
    expect(page).to have_link(I18n.t("cookie_banner.policy_link"), href: cookies_path, visible: :hidden)
  end
end
