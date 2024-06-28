# frozen_string_literal: true

require "rails_helper"

RSpec.describe CookieConsentFormComponent::View, type: :component do
  it "contains a hidden form for setting the analytics cookie preference" do
    render_inline(described_class.new)

    expect(page).to have_css("legend", text: "Do you want to accept analytics cookies?", visible: :hidden)
    expect(page).to have_field("Yes", type: :radio, visible: :hidden)
    expect(page).to have_field("No", type: :radio, visible: :hidden)
    expect(page).to have_button("Save cookie settings", visible: :hidden)
  end
end
