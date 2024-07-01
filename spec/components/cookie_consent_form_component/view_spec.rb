# frozen_string_literal: true

require "rails_helper"

RSpec.describe CookieConsentFormComponent::View, type: :component do
  before do
    allow(Settings).to receive(:analytics_enabled).and_return(analytics_enabled)
  end

  context "with analytics enabled" do
    let(:analytics_enabled) { true }

    it "shows the non-JS message" do
      render_inline(described_class.new)

      expect(page).to have_text("We cannot change your cookie settings at the moment because JavaScript is not running in your browser.")
    end

    it "contains a hidden form for setting the analytics cookie preference" do
      render_inline(described_class.new)

      expect(page).to have_css("legend", text: "Do you want to accept analytics cookies?", visible: :hidden)
      expect(page).to have_field("Yes", type: :radio, visible: :hidden)
      expect(page).to have_field("No", type: :radio, visible: :hidden)
      expect(page).to have_button("Save cookie settings", visible: :hidden)
    end
  end

  context "without analytics enabled" do
    let(:analytics_enabled) { false }

    it "does not show the non-JS message" do
      render_inline(described_class.new)

      expect(page).not_to have_text("We cannot change your cookie settings at the moment because JavaScript is not running in your browser.")
    end

    it "does not contain the hidden form for setting the analytics cookie preference" do
      render_inline(described_class.new)

      expect(page).not_to have_css("legend", text: "Do you want to accept analytics cookies?", visible: :hidden)
      expect(page).not_to have_field("Yes", type: :radio, visible: :hidden)
      expect(page).not_to have_field("No", type: :radio, visible: :hidden)
      expect(page).not_to have_button("Save cookie settings", visible: :hidden)
    end
  end
end
