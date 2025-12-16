require "rails_helper"

RSpec.describe CheckYourAnswersComponent::View, type: :component do
  include Rails.application.routes.url_helpers

  let(:form) { build :form, id: 1 }
  let(:question) { build :text, question_text: "Do you want to remain anonymous?", text: "Yes" }
  let(:optional_question) { build :text, question_text: "Optional question", is_optional: true, text: "" }
  let(:steps) do
    [
      build(:step, question: question, page: build(:page, :with_text_settings)),
      build(:step, question: optional_question, page: build(:page, :with_text_settings)),
    ]
  end
  let(:mode) { Mode.new("form") }

  before do
    render_inline(described_class.new(form:, steps:, mode:))
  end

  it "renders a row for each step" do
    expect(page).to have_css(".govuk-summary-list__row", count: 2)
  end

  it "displays the question text and answer for each step" do
    expect(page).to have_css(".govuk-summary-list__key", text: "Do you want to remain anonymous?")
    expect(page).to have_css(".govuk-summary-list__value", text: "Yes")
    expect(page).to have_css(".govuk-summary-list__key", text: "Optional question (optional)")
    expect(page).to have_css(".govuk-summary-list__value", text: "Not completed")
  end

  it "displays the question text with '(optional)' for optional questions" do
    expect(page).to have_xpath "(//dl)/div[1]/dt", text: "Do you want to remain anonymous?"
    expect(page).to have_xpath "(//dl)/div[2]/dt", text: "Optional question (optional)"
  end

  it "displays the answer for answered question" do
    expect(page).to have_xpath "(//dl)/div[1]/dd", text: "Yes"
  end

  it "displays 'Not completed' for unanswered optional questions" do
    expect(page).to have_xpath "(//dl)/div[2]/dd", text: "Not completed"
  end

  it "includes change links for each step" do
    expect(page).to have_link("Change", href: form_change_answer_path(mode: mode, form_id: form.id, form_slug: form.form_slug, page_slug: steps[0].id))
    expect(page).to have_link("Change", href: form_change_answer_path(mode: mode, form_id: form.id, form_slug: form.form_slug, page_slug: steps[1].id))
  end

  context "when a step is repeatable and has an answer" do
    let(:steps) { [ build(:repeatable_step, question: question, page: build(:page, :with_text_settings)) ] }

    it "uses the add another answer path for the change link" do
      expect(page).to have_link("Change", href: change_add_another_answer_path(mode: mode, form_id: form.id, form_slug: form.form_slug, page_slug: steps[0].id))
    end
  end

  context "when there is a long_text text question" do
    let(:question) { build :text, :with_long_text, question_text: "Do you want to remain anonymous?" }

    it "displays the summary list full width" do
      expect(page).not_to have_css(".govuk-grid-column-two-thirds-from-desktop .govuk-summary-list")
      expect(page).to have_css(".govuk-grid-column-full .govuk-summary-list")
    end
  end

  context "when there is no long_text text question" do
    it "displays the summary list at two-thirds width" do
      expect(page).not_to have_css(".govuk-grid-column-full .govuk-summary-list")
      expect(page).to have_css(".govuk-grid-column-two-thirds-from-desktop .govuk-summary-list")
    end
  end
end
