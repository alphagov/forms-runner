require "rails_helper"

RSpec.describe FormHeaderComponent::View, type: :component do
  let(:mode) { Mode.new }
  let(:form) { OpenStruct.new(id: 1, name: "test_form_name", form_slug: "test") }
  let(:current_context) { OpenStruct.new(form:) }

  it "has service name" do
    render_inline(described_class.new(current_context:, mode:, service_url_overide: "/form/1/test"))

    expect(page).to have_selector(".govuk-header__service-name")
    expect(page).to have_text("test_form_name")
  end

  context "when mode is preview_draft" do
    let(:mode) { Mode.new("preview-draft") }

    it "has service name" do
      render_inline(described_class.new(current_context:, mode:, service_url_overide: "/form/1/test"))

      expect(page).to have_selector(".govuk-header__service-name")
      expect(page).to have_selector(".app-header--preview-draft")
      expect(page).to have_content("test_form_name")
    end
  end

  context "when mode is preview_live" do
    let(:mode) { Mode.new("preview-live") }

    it "has service name" do
      render_inline(described_class.new(current_context:, mode:, service_url_overide: "/form/1/test"))

      expect(page).to have_selector(".govuk-header__service-name")
      expect(page).to have_selector(".app-header--preview-live")
      expect(page).to have_content("test_form_name")
    end
  end

  context "when the environment is production" do
    before do
      allow(HostingEnvironment).to receive(:friendly_environment_name).and_return("production")
      render_inline(described_class.new(current_context:, mode:, service_url_overide: "/form/1/test"))
    end

    it "does not show an environment tag" do
      expect(page).not_to have_css(".govuk-tag", text: "production")
    end
  end

  [
    { name: "local", colour: "pink" },
    { name: "development", colour: "green" },
    { name: "user research", colour: "blue" },
    { name: "staging", colour: "yellow" },
  ].each do |environment|
    context "when the environment is #{environment[:name]}" do
      before do
        allow(HostingEnvironment).to receive(:friendly_environment_name).and_return(environment[:name])
        render_inline(described_class.new(current_context:, mode:, service_url_overide: "/form/1/test"))
      end

      it "shows the environment tag" do
        expect(page).to have_css(".govuk-tag--#{environment[:colour]}", text: environment[:name])
      end
    end
  end

  it "does not show if current_context is nil" do
    render_inline(described_class.new(current_context: nil, mode:, service_url_overide: "/form/1/test"))
    expect(page).not_to have_selector(".govuk-header__service-name")
  end
end
