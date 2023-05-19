require "rails_helper"

RSpec.describe FormHeaderComponent::View, type: :component do
  let(:mode) { Mode.new }
  let(:form) { OpenStruct.new(id: 1, name: "test_form_name", form_slug: "test") }
  let(:current_context) { OpenStruct.new(form:) }

  it "has service name" do
    render_inline(described_class.new(current_context:, mode:, service_url_overide: "/form/1/test"))

    expect(page).to have_selector(".govuk-header__service-name")
    expect(page).to have_content("test_form_name")
  end

  context "when mode is preview_draft" do
    let(:mode) { Mode.new("preview-draft") }

    it "has service name" do
      render_inline(described_class.new(current_context:, mode:, service_url_overide: "/form/1/test"))

      expect(page).to have_selector(".govuk-header__service-name")
      expect(page).to have_selector(".govuk-header--preview-draft")
      expect(page).to have_content("test_form_name")
    end
  end

  context "when mode is preview_live" do
    let(:mode) { Mode.new("preview-live") }

    it "has service name" do
      render_inline(described_class.new(current_context:, mode:, service_url_overide: "/form/1/test"))

      expect(page).to have_selector(".govuk-header__service-name")
      expect(page).to have_selector(".govuk-header--preview-live")
      expect(page).to have_content("test_form_name")
    end
  end

  it "does not show if current_context is nil" do
    render_inline(described_class.new(current_context: nil, mode:, service_url_overide: "/form/1/test"))
    expect(page).not_to have_selector(".govuk-header__service-name")
  end
end
