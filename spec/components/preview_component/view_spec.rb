require "rails_helper"

RSpec.describe PreviewComponent::View, type: :component do
  it "shows in preview_draft" do
    mode = Mode.new('preview-draft')
    render_inline(described_class.new(mode: mode))
    expect(page).to have_selector(".govuk-phase-banner")
    expect(page).to have_content("Draft preview")
    expect(page).to have_content("You're previewing the draft version of this form")
  end

  it "shows in preview_live" do
    mode = Mode.new('preview-live')
    render_inline(described_class.new(mode: mode))
    expect(page).to have_selector(".govuk-phase-banner")
    expect(page).to have_content("Live preview")
    expect(page).to have_content("You're previewing the live version of this form")
  end

  it "does not show in live" do
    mode = Mode.new('form')
    render_inline(described_class.new(mode: mode))
    expect(page).not_to have_selector(".govuk-phase-banner")
  end
end
