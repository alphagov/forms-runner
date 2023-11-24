require "rails_helper"

RSpec.describe PreviewBannerComponent::View, type: :component do
  it "shows in preview_draft" do
    mode = Mode.new("preview-draft")
    render_inline(described_class.new(mode:))
    expect(page).to have_selector(".govuk-notification-banner")
    expect(page).to have_content(I18n.t("preview_banner.title"))
    expect(page).to have_content(I18n.t("preview_banner.heading"))
  end

  it "shows in preview_live" do
    mode = Mode.new("preview-live")
    render_inline(described_class.new(mode:))
    expect(page).to have_selector(".govuk-notification-banner")
    expect(page).to have_content(I18n.t("preview_banner.title"))
    expect(page).to have_content(I18n.t("preview_banner.heading"))
  end

  it "does not show in live" do
    mode = Mode.new("form")
    render_inline(described_class.new(mode:))
    expect(page).not_to have_selector(".govuk-notification-banner")
  end
end
