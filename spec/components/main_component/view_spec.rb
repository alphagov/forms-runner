require "rails_helper"

RSpec.describe MainComponent::View, type: :component do
  it "returns the main content ID" do
    render_inline(described_class.new)
    expect(page).to have_selector("#main-content")
  end

  it "does not return the main content ID" do
    render_inline(described_class.new(is_component_preview: true))
    expect(page).not_to have_selector("#main-content")
  end
end
