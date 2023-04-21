require "rails_helper"

RSpec.describe MainComponent::View, type: :component do
  it "adds class for mode" do
    mode = "preview-draft"
    render_inline(described_class.new(mode:))
    expect(page).to have_selector(".main--preview-draft")
  end

  it "does not add class for empty mode" do
    mode = ""
    render_inline(described_class.new(mode:))
    expect(page).not_to have_selector(".main--")
  end

  it "adds question class if is_question is true" do
    mode = ""
    render_inline(described_class.new(mode:, is_question: true))
    expect(page).to have_selector(".main--question")
  end

  it "does not add question class if is_question is not true" do
    mode = ""
    render_inline(described_class.new(mode:))
    expect(page).not_to have_selector(".main--question")
  end
end
